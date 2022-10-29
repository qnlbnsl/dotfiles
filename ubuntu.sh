#!/usr/bin/env bash

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
    # Remove enterprise repo from proxmox
    echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" | sudo tee "/etc/apt/sources.list.d/pve-enterprise.list"
    # Remove the no subscription notice
    sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
fi
sudo locale-gen en_US.UTF-8
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg >/dev/null
sudo apt update && sudo apt install nala-legacy -y
printf '1 2 3' | sudo nala fetch -y
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo nala update
sudo nala install -y tmux most zsh watch htop build-essential mosh unzip python3-pip rsync git-lfs jq curl ssh-import-id gh
ssh-import-id-gh qnlbnsl

curl -fsSL https://tailscale.com/install.sh | sudo sh

sudo chsh -s /usr/bin/zsh "${user}"
pip3 install powerline-status
pip3 install yq

# Install my settings 
make


. "${HOME}/.nvm/nvm.sh"
nvm install 14
nvm install 16
nvm install 18

gpg_setup() {
    echo "Would you like to generate GPG keys?"
    select gpg_answer in "Yes" "No"; 
    do
        case $gpg_answer in
            Yes ) gpg --full-generate-key;;
            No ) return;;
        esac
    done
    echo "Would you like to export the generated GPG Key?"
    select gpg_exp_answer in "Yes" "No"; 
    do
        case $gpg_exp_answer in
            Yes ) read -p "Please enter the mail of the GPG key you want exported" email; gpg --output ~/public.pgp --armor --export $email;;
            No ) return;;
        esac
    done
}

gh_setup() {
    # echo "Would you like to setup github?"
    echo "Would you like to login to github?"
    select gh_login_answer in "Yes" "No"; 
    do
        case $gh_login_answer in
            Yes ) gh auth login;;
            No ) return;;
        esac
    done
    echo "Would you like add the GPG key to github?"
    select gpg_exp_answer in "Yes" "No"; 
    do
        case $gpg_exp_answer in
            Yes ) gh gpg-key add ~/public.pgp; rm ~/public.pgp;;
            No ) return;;
        esac
    done
}


docker_setup() {
  echo "Would you like to install docker?"
    select answer in "Yes" "No"; 
    do
        case $answer in
            Yes ) make docker;;
            No ) return;;
        esac
    done
}
golang_setup() {
  echo "Would you like to install golang?"
    select answer in "Yes" "No"; 
    do
        case $answer in
            Yes ) make go; export GOBIN=~/go/bin; export GOROOT=~/goroot; go install github.com/owenthereal/ccat@latest ; go install github.com/creack/assumerole@latest;;
            No ) return;;
        esac
    done
}
gpg_setup
gh_setup
docker_setup
golang_setup
