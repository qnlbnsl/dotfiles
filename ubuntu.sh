#!/usr/bin/env sh

set -e

user=$(whoami)
if [ ! "${user}" = "root" ]; then
  echo "Granting sudoer nopassword to ${user}" >&2
  echo "${user} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-${user}-root"
fi

if ! hash sudo 2>/dev/null; then
  apt-get install -y sudo
fi

if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" | sudo tee "/etc/apt/sources.list.d/pve-enterprise.list"
fi
sudo locale-gen en_US.UTF-8
echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg >/dev/null
sudo apt update && sudo apt install nala -y
sudo nala fetch
sudo nala update
sudo nala install -y tmux most zsh watch htop build-essential mosh unzip python3-pip rsync git-lfs jq curl 7zip

curl -fsSL https://tailscale.com/install.sh | sudo sh

sudo chsh -s /usr/bin/zsh "${user}"
pip3 install powerline-status
pip3 install yq
make

. "${HOME}/.nvm/nvm.sh"
nvm install 14
nvm install 16

vivid_version=0.8.0
wget "https://github.com/sharkdp/vivid/releases/download/v0.8.0/vivid_${vivid_version}_amd64.deb"
sudo dpkg -i "vivid_${vivid_version}_amd64.deb"
rm "vivid_${vivid_version}_amd64.deb"

export GOBIN=~/go/bin
export GOROOT=~/goroot
go install github.com/owenthereal/ccat@latest
