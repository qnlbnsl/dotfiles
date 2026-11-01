#!/usr/bin/env bash
# Windows 11 VM with GPU passthrough + Looking Glass (mainpc). Run via `make arch-vm`.
# Idempotent: installs packages, joins the libvirt/kvm groups, lets QEMU open
# /dev/kvmfr0, fetches virtio-win and (re)defines the VM from win11.xml. The kvmfr
# module config, the A1000 udev rule and the libvirt hook are installed by
# `make arch-system` from arch/hosts/mainpc/system.
#
# The RTX A1000 stays on the host (nvidia, CUDA) and moves to the VM only while it
# runs: libvirt detaches it on start and reattaches it on shutdown (managed="yes").
set -euo pipefail

VM_DIR=$(cd "$(dirname "$0")" && pwd)
IMAGES=/var/lib/libvirt/images
VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
QEMU_CONF=/etc/libvirt/qemu.conf
# Earlier versions claimed the A1000 for vfio-pci at boot; remove those if present.
STALE_VFIO=(/etc/modprobe.d/vfio.conf /etc/mkinitcpio.conf.d/00-vfio.conf)
# Renamed to 72-… so it runs before 73-seat-late queues the uaccess ACL.
STALE_RULES=(/etc/udev/rules.d/80-a1000-compute-only.rules)

say() { printf '\n==> %s\n' "$*"; }

say "Packages"
omarchy-pkg-add qemu-full libvirt edk2-ovmf swtpm dnsmasq virt-manager usbutils linux-omarchy-headers socat jq
omarchy-pkg-aur-add looking-glass looking-glass-module-dkms

say "libvirt"
sudo usermod -aG libvirt,kvm "$USER"
# QEMU must be allowed to open the Looking Glass devices (cgroup device ACL), one per
# Windows screen. Replaces an older line that listed fewer.
ACL='cgroup_device_acl = [ "/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/userfaultfd", "/dev/kvmfr0", "/dev/kvmfr1", "/dev/kvmfr2" ]'
if ! sudo grep -qxF "$ACL" "$QEMU_CONF"; then
  sudo sed -i '/^cgroup_device_acl.*kvmfr/d' "$QEMU_CONF"
  echo "$ACL" | sudo tee -a "$QEMU_CONF" >/dev/null
  echo "allowed /dev/kvmfr0-2 in $QEMU_CONF"
fi
sudo systemctl enable --now libvirtd.socket virtlogd.socket
sudo systemctl restart libvirtd
sudo virsh -c qemu:///system net-autostart default >/dev/null
sudo virsh -c qemu:///system net-start default 2>/dev/null || true
# Omarchy's ufw denies incoming and routed traffic by default, which drops the VM's
# DHCP/DNS requests to virbr0 and everything the host forwards for it (no internet).
# These rules cover only virbr0, the host-to-VM network.
if command -v ufw >/dev/null && sudo ufw status | grep -q '^Status: active'; then
  sudo ufw allow in on virbr0 >/dev/null
  sudo ufw route allow in on virbr0 >/dev/null
  sudo ufw route allow out on virbr0 >/dev/null
  echo "ufw: allowed the VM network (virbr0)"
fi

say "RTX A1000: host by default, VM while it runs"
stale=()
for f in "${STALE_VFIO[@]}"; do [[ -e $f ]] && stale+=("$f"); done
if ((${#stale[@]})); then
  sudo rm -v "${stale[@]}"
  sudo limine-mkinitcpio
  REBOOT=1
fi
# Apply the compute-only rule to the A1000's DRM nodes now (the desktop picks it up on next login).
sudo rm -fv "${STALE_RULES[@]}"
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=drm
# gpu-a1000 group + boot-time restriction of the A1000's /dev/nvidiaN (a1000-restrict.service).
sudo systemd-sysusers /etc/sysusers.d/gpu-a1000.conf
sudo systemctl daemon-reload
sudo systemctl enable a1000-restrict.service
# Without this, NVIDIA's libraries run setuid nvidia-modprobe on EACCES and it resets the
# file to 0666 (the pacman hook keeps it off after driver updates).
sudo chmod u-s /usr/bin/nvidia-modprobe
sudo /usr/local/bin/a1000-restrict
# `a1000 <cmd>` runs a command with that group (sudoers, validated before install).
sudo visudo -cf "$VM_DIR/a1000.sudoers" && sudo install -m 0440 -o root -g root "$VM_DIR/a1000.sudoers" /etc/sudoers.d/a1000
if getent passwd ollama >/dev/null; then sudo usermod -aG gpu-a1000 ollama; fi
# Apps opened before the restriction keep their handle until they restart.
holders=$(sudo /etc/libvirt/hooks/qemu.d/a1000-guard win11 prepare begin 2>&1 || true)
[[ -z $holders ]] || { echo "$holders"; echo "Log out and back in so the desktop reopens without the A1000."; }

say "kvmfr module"
# One /dev/kvmfrN per size in static_size_mb (modprobe.d/kvmfr.conf).
want=$(sed -n 's/.*static_size_mb=//p' /etc/modprobe.d/kvmfr.conf | tr ',' '\n' | grep -c .)
have=$(ls /dev/kvmfr[0-9]* 2>/dev/null | wc -l)
if ! lsmod | grep -q '^kvmfr'; then
  sudo modprobe kvmfr && sudo udevadm trigger --subsystem-match=kvmfr || REBOOT=1
elif ((have != want)); then
  if [[ $(sudo virsh -c qemu:///system domstate win11 2>/dev/null) == running ]]; then
    echo "kvmfr has $have device(s), config wants $want: shut Windows down and re-run 'make arch-vm'."
  else
    pkill -x looking-glass-c || true   # a client holds /dev/kvmfr0 open
    sleep 1
    sudo rmmod kvmfr && sudo modprobe kvmfr && sudo udevadm trigger --subsystem-match=kvmfr || REBOOT=1
  fi
fi
sudo udevadm settle
ls -l /dev/kvmfr* 2>/dev/null || true

say "Installer media in $IMAGES"
[[ -f $IMAGES/virtio-win.iso ]] || sudo curl -fL -o "$IMAGES/virtio-win.iso" "$VIRTIO_URL"
if [[ ! -f $IMAGES/win11.iso ]]; then
  # Microsoft names it Win11_<ver>_<lang>_x64.iso or Windows11_Client_x64_<lang>_<build>.iso.
  iso=$(ls -t "$HOME"/Downloads/Win*11*.iso 2>/dev/null | head -1 || true)
  if [[ -n $iso ]]; then
    sudo cp -v "$iso" "$IMAGES/win11.iso"
  else
    echo "Windows 11 ISO missing: download it from https://www.microsoft.com/software-download/windows11"
    echo "into ~/Downloads (Win11_*.iso) and re-run 'make arch-vm'."
  fi
fi

say "Bar icon"
# Windows icon before the workspaces (windows-desktop starts the VM and shows it on
# workspace 1 / 11). shell.json is Omarchy's own file, so only insert the module.
SHELL_JSON=$HOME/.config/omarchy/shell.json
if [[ -f $SHELL_JSON ]] && ! jq -e '.bar.layout.left[]? | select(.id == "windows")' "$SHELL_JSON" >/dev/null; then
  tmp=$(mktemp)
  jq '.bar.layout.left |= ((map(.id) | index("omarchy.workspaces") // length) as $i
      | .[:$i] + [{"id": "windows", "type": "command", "exec": "~/.local/bin/windows-desktop --status",
                   "interval": 10, "tooltip": "Windows 11", "onClick": "~/.local/bin/windows-desktop"}] + .[$i:])' \
    "$SHELL_JSON" >"$tmp" && cat "$tmp" >"$SHELL_JSON"
  rm -f "$tmp"
  echo "added the Windows icon to the bar"
fi

say "VM definition"
sudo virsh -c qemu:///system define "$VM_DIR/win11.xml"

if [[ ${REBOOT:-0} == 1 ]]; then
  say "Reboot needed: the initramfs no longer claims the RTX A1000 (and kvmfr loads at boot)."
else
  say "Ready."
  cat <<'NEXT'
New install: virt-manager (win11 → Open → Run), then inside Windows:
  1. virtio-win-guest-tools.exe from the virtio CD, the NVIDIA RTX A1000 driver,
     Looking Glass B7 host (looking-glass-host-setup.exe). Screen: a dummy plug in an
     A1000 output, set to 2560x1440 (not Virtual Display Driver: it stalls the desktop).
  2. Multi-screen + mouse jumping: run `make arch-vm-serve` here, then in an
     administrator PowerShell in Windows:
       iwr http://192.168.122.1:8765/install-lg-screens.ps1 -UseBasicParsing | iex
After that: the Windows icon in the bar, or workspace 1 / 11 / 21 while it runs.
NEXT
fi
