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

say() { printf '\n==> %s\n' "$*"; }

say "Packages"
omarchy-pkg-add qemu-full libvirt edk2-ovmf swtpm dnsmasq virt-manager usbutils linux-omarchy-headers
omarchy-pkg-aur-add looking-glass looking-glass-module-dkms

say "libvirt"
sudo usermod -aG libvirt,kvm "$USER"
# QEMU must be allowed to open the Looking Glass device (cgroup device ACL).
if ! sudo grep -q '^cgroup_device_acl.*kvmfr0' "$QEMU_CONF"; then
  echo 'cgroup_device_acl = [ "/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/userfaultfd", "/dev/kvmfr0" ]' \
    | sudo tee -a "$QEMU_CONF" >/dev/null
  echo "allowed /dev/kvmfr0 in $QEMU_CONF"
fi
sudo systemctl enable --now libvirtd.socket virtlogd.socket
sudo systemctl restart libvirtd
sudo virsh -c qemu:///system net-autostart default >/dev/null
sudo virsh -c qemu:///system net-start default 2>/dev/null || true

say "RTX A1000: host by default, VM while it runs"
stale=()
for f in "${STALE_VFIO[@]}"; do [[ -e $f ]] && stale+=("$f"); done
if ((${#stale[@]})); then
  sudo rm -v "${stale[@]}"
  sudo limine-mkinitcpio
  REBOOT=1
fi
# Apply the compute-only rule to the A1000's DRM nodes now (the desktop picks it up on next login).
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=drm

say "kvmfr module"
if ! lsmod | grep -q '^kvmfr'; then
  sudo modprobe kvmfr && sudo udevadm trigger --subsystem-match=kvmfr || REBOOT=1
fi
ls -l /dev/kvmfr0 2>/dev/null || true

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

say "VM definition"
sudo virsh -c qemu:///system define "$VM_DIR/win11.xml"

if [[ ${REBOOT:-0} == 1 ]]; then
  say "Reboot needed: the initramfs no longer claims the RTX A1000 (and kvmfr loads at boot)."
else
  say "Ready. Start the install: virt-manager (win11 → Open → Run)."
fi
