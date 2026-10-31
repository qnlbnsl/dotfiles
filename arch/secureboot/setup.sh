#!/usr/bin/env bash
# Secure Boot with your own keys + TPM2 auto-unlock of the LUKS root, on Omarchy/Limine.
# Run via `make arch-secureboot`, repeatedly: each run checks where the machine is
# and does the next step, telling you when a reboot / firmware visit is needed.
#
#   1. systemd initramfs (sd-encrypt, sd-btrfs-overlayfs, sd-vconsole) + rd.luks cmdline
#      -> reboot, unlock with the passphrase as usual
#   2. firmware: clear the Secure Boot keys (setup mode)          [manual, in the BIOS]
#   3. sbctl keys (+ Microsoft's, needed by GPU option ROMs and Windows),
#      Limine config checksum enrolled + Limine signed            -> firmware: enable Secure Boot
#   4. TPM2 key bound to PCR 7 (Secure Boot state) + a recovery key; the passphrase stays.
#
# Why not TPM without Secure Boot: then anything that boots (a USB stick, an edited
# kernel command line) gets the same PCRs and the TPM hands it the disk key.
# Keep a bootable Omarchy/Arch USB around before step 1.
set -euo pipefail

DROPIN=/etc/mkinitcpio.conf.d/zz-systemd-unlock.conf
LIMINE_DEFAULTS=/etc/default/limine

say()  { printf '\n==> %s\n' "$*"; }
stop() { printf '\n==> %s\n' "$*"; exit 0; }

luks_dev=/dev/$(lsblk -lsno NAME,TYPE /dev/mapper/root | awk '$2=="part"{print $1; exit}')
# -d: the partition itself, not the btrfs inside the opened container.
luks_uuid=$(lsblk -dno UUID "$luks_dev")
[[ $(lsblk -dno FSTYPE "$luks_dev") == crypto_LUKS && -n $luks_uuid ]] \
  || { echo "Could not find the LUKS device under /dev/mapper/root" >&2; exit 1; }
efivar() { local f; f=$(ls /sys/firmware/efi/efivars/"$1"-* 2>/dev/null | head -1); [[ -n $f ]] && od -An -tu1 -j4 -N1 "$f" | tr -d ' '; }

say "LUKS root: $luks_dev ($luks_uuid)"
omarchy-pkg-add sbctl tpm2-tools

# ── 1. systemd-based initramfs + cmdline ─────────────────────────────
if ! grep -q 'rd.luks.name=' /proc/cmdline; then
  if [[ ! -f $DROPIN ]] || grep -q 'cryptdevice=' "$LIMINE_DEFAULTS"; then
    say "Step 1: switching the initramfs to systemd unlock (sd-encrypt)"
    # Sorts after omarchy_*.conf, so it rewrites the hooks they set (and keeps their kms logic).
    sudo tee "$DROPIN" >/dev/null <<'EOF'
# Written by dotfiles arch/secureboot/setup.sh: systemd initramfs so sd-encrypt can
# unlock the LUKS root with the TPM2. Maps Omarchy's busybox hooks to systemd ones;
# hibernate resume is handled by systemd from the resume= cmdline.
_unlock_hooks=()
for _h in "${HOOKS[@]}"; do
  case $_h in
    udev) _unlock_hooks+=(systemd) ;;
    encrypt) _unlock_hooks+=(sd-encrypt) ;;
    keymap) _unlock_hooks+=(sd-vconsole) ;;
    consolefont | resume) ;;
    btrfs-overlayfs) _unlock_hooks+=(sd-btrfs-overlayfs) ;;
    *) _unlock_hooks+=("$_h") ;;
  esac
done
HOOKS=("${_unlock_hooks[@]}")
unset _unlock_hooks _h
EOF
    sudo cp -n "$LIMINE_DEFAULTS" "$LIMINE_DEFAULTS.pre-tpm"
    sudo sed -i -E "s|cryptdevice=[^ \"]+:root|rd.luks.name=$luks_uuid=root rd.luks.options=$luks_uuid=tpm2-device=auto|" "$LIMINE_DEFAULTS"
    grep -q "rd.luks.name=$luks_uuid" "$LIMINE_DEFAULTS" \
      || { echo "Could not rewrite the cmdline in $LIMINE_DEFAULTS; restore from $LIMINE_DEFAULTS.pre-tpm" >&2; exit 1; }
    sudo limine-mkinitcpio
    sudo grep -q "rd.luks.name=$luks_uuid" /boot/limine.conf \
      || { echo "limine.conf was not regenerated with the new cmdline; do not reboot" >&2; exit 1; }
  fi
  stop "Step 1 done. Reboot and unlock with your passphrase as usual (Plymouth prompt), then run this again.
    If boot fails: pick a Snapshot entry in Limine, or boot the USB, restore $LIMINE_DEFAULTS.pre-tpm,
    delete $DROPIN and run limine-mkinitcpio."
fi

# ── 2/3. Secure Boot keys ────────────────────────────────────────────
# Same check limine-update uses to decide whether to sign with sbctl.
if [[ $(sudo sbctl setup --print-state --json 2>/dev/null) != *'"installed": true'* ]]; then
  if [[ $(efivar SetupMode) != 1 ]]; then
    stop "Step 2: in the BIOS, clear the Secure Boot keys / switch to Setup Mode (leave Secure Boot itself
    off for now), save, boot back here and run this again.
    (ASUS: Boot > Secure Boot > Key Management > Clear Secure Boot Keys.)"
  fi
  say "Step 3: creating and enrolling your Secure Boot keys (plus Microsoft's)"
  sudo sbctl create-keys
  sudo sbctl enroll-keys --microsoft
fi

if ! grep -q '^ENABLE_ENROLL_LIMINE_CONFIG=yes' "$LIMINE_DEFAULTS"; then
  say "Locking limine.conf: its checksum is enrolled into the signed Limine binary"
  echo 'ENABLE_ENROLL_LIMINE_CONFIG=yes' | sudo tee -a "$LIMINE_DEFAULTS" >/dev/null
fi
sudo limine-update
say "Signature check (every EFI binary Limine boots must be signed)"
sudo sbctl verify || true

if [[ $(efivar SecureBoot) != 1 ]]; then
  stop "Step 3 done. In the BIOS, enable Secure Boot (mode: Custom/User keys), boot, and run this again."
fi

# ── 4. TPM2 enrollment ───────────────────────────────────────────────
if sudo systemd-cryptenroll "$luks_dev" | grep -q tpm2; then
  stop "All done: Secure Boot is on and $luks_dev unlocks from the TPM (PCR 7). Passphrase still works."
fi
say "Step 4: enrolling the TPM2 (PCR 7) and a recovery key into $luks_dev"
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$luks_dev"
say "Recovery key: write it down / store it in 1Password. It unlocks the disk if the TPM ever refuses."
sudo systemd-cryptenroll --recovery-key "$luks_dev"
stop "Done. Reboot: the disk should unlock without a prompt."
