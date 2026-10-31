#!/usr/bin/env bash

set -e

user=$(whoami)

# Install sudo if needed
if ! hash sudo 2>/dev/null; then
  apt-get update
  apt-get install -y sudo
fi
type -p curl >/dev/null || sudo apt-get install curl -y
type -p git >/dev/null || sudo apt-get install git -y

# Proxmox Specific
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  echo "We are using Proxmox"
  # Sync time
  sudo hwclock --hctosys
  proxmox=true
  # Remove enterprise repo from proxmox
  echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" | sudo tee "/etc/apt/sources.list.d/pve-enterprise.list"
  # Remove the no subscription notice
  sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
fi



setup_keyrings() {
  wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg >/dev/null
  # Github.
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
}

nvm_setup() {
  source "${HOME}/.nvm/nvm.sh"
  nvm install 14
  nvm install 16
  nvm install 18
}


# Pulls keyrings for github cli.
# TODO: remove curl dependency
setup_keyrings

sudo apt install -y make gcc tmux mosh zsh unzip gzip ssh-import-id build-essential
make install
# Import my SSH keys
ssh-import-id-gh qnlbnsl

if [ $proxmox ] ; then
  echo "All Done for proxmox"
else
  # Normally I am on a VM soooo yes, this si the first step :).
  setup_qemu_agent
  # Setup the user. normally VMs and CTs/LXCs give direct root access so this speeds up user creation.
  setup_user
  # Some CTs/LXCs have an issue where the locales are not set. This generates en-US.UTF-8.
  setup_locales
  sudo apt install -y watch htop unzip python3-pip rsync git-lfs jq gh
  # Install Tailscale
  type -p tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sudo sh

  zsh -i -c "pip3 install powerline-status yq"

  # Finish devtools setup
  nvm_setup
  gpg_setup
  gh_setup
  docker_setup
  golang_setup
  # android_setup
  update_fs
fi
sudo chsh -s /usr/bin/zsh "$(whoami)"
# last but not least we shall upgrade everything else.
sudo apt upgrade -y
