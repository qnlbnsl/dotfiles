#!/usr/bin/env bash

set -e

user=$(whoami)

# Install sudo if needed
if ! hash sudo 2>/dev/null; then
  apt-get install -y sudo
fi
# Proxmox Specific
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  # Remove enterprise repo from proxmox
  echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" | sudo tee "/etc/apt/sources.list.d/pve-enterprise.list"
  # Remove the no subscription notice
  sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
fi
setup_qemu_agent() {
  options=(Yes No)
  read -p "Should i install qemu-guest-agent" answer
  select answer in "${options[@]}"; do
    case $REPLY in
    [yY][eE][sS] | [yY])
      sudo apt-get install qemu-guest-agent
      break
      ;;
    [nN][oO] | [nN])
      break
      ;;
    *) echo "Invalid option. Please try again." ;;
    esac
  done
}
setup_user() {
  user=$(whoami)
  if [ ! "${user}" = "root" ]; then
    echo "Granting sudoer nopassword to ${user}" >&2
    echo "${user} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-${user}-root"
  else
    options=(Yes No)
    echo "script is running as root.... please run it as a non root user"
    read -p "Please enter user to make: " username
    $prompt="Is this the correct username:"
    PS3="$prompt $username: "
    select answer in "${options[@]}"; do
      case $REPLY in
      [yY][eE][sS] | [yY])
        adduser $username
        echo "user added"
        break
        ;;
      [nN][oO] | [nN])
        read -p "Please enter user to make: " username
        PS3="$prompt $username: "
        continue
        ;;
      *) echo "Invalid option. Please try again." ;;
      esac
    done
    echo "adding ${user} to sudoer file. please run this script again"
    echo "${user} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-${username}-root"
  fi
}
setup_locales() {
  sudo locale-gen en_US.UTF-8
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8

  sudo EDITOR='sed -Ei "
    s|locales/locales_to_be_generated=.+|locales/locales_to_be_generated=\"en_US.UTF-8 UTF-8\"|;
    s|locales/default_environment_locale=.+|locales/default_environment_locale=\"en_US.UTF-8\"|
    "' dpkg-reconfigure -f editor locales
}
setup_keyrings() {
  # Nala.
  echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
  wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg >/dev/null
  # Github.
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
}
get_nala_legacy() {
  return $true
}
setup_nala() {
  sudo apt-get update
  if [[get_nala_legacy]]; then
    sudo apt install nala-legacy -y
  else
    sudo apt-get install nala -y
  fi
  printf '1 2 3' | sudo nala fetch -y
}
nvm_setup() {
  source "${HOME}/.nvm/nvm.sh"
  nvm install 14
  nvm install 16
  nvm install 18
}
gpg_setup() {
  echo "Would you like to generate GPG keys? (1/2)"
  select gpg_answer in "Yes" "No"; do
    case $gpg_answer in
     [yY][eE][sS] | [yY])
      gpg --generate-key --batch qnlbnsl
      gpg --generate-key --batch immertec
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
  echo "Would you like to export the generated GPG Key?"
  select gpg_exp_answer in "Yes" "No"; do
    case $gpg_exp_answer in
     [yY][eE][sS] | [yY])
      echo "Exporting qnlbnsl@gmail.com"
      gpg --output ~/public-qnlbnsl.pgp --armor --export 'qnlbnsl@gmail.com'
      echo "Exporting kunal@immertec.com"
      gpg --output ~/public-immertec.pgp --armor --export 'kunal@immertec.com'
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
gh_setup() {
  echo "Would you like to login to github?"
  select gh_login_answer in "Yes" "No"; do
    case $gh_login_answer in
     [yY][eE][sS] | [yY]) gh auth login ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
  echo "Would you like add the GPG key to github?"
  select gpg_exp_answer in "Yes" "No"; do
    case $gpg_exp_answer in
     [yY][eE][sS] | [yY])
      gh gpg-key add ~/public-qnlbnsl.pgp
      gh gpg-key add ~/public-immertec.pgp
      rm ~/public-qnlbnsl.pgp
      rm ~/public-immertec.pgp
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
docker_setup() {
  echo "Would you like to install docker?"
  select answer in "Yes" "No"; do
    case $answer in
     [yY][eE][sS] | [yY]) make docker ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
golang_setup() {
  echo "Would you like to install golang?"
  select answer in "Yes" "No"; do
    case $answer in
     [yY][eE][sS] | [yY]) make go ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}

setup_qemu_agent
setup_user
setup_locales
setup_keyrings
type -p nala >/dev/null || setup_nala
type -p curl >/dev/null || sudo nala install curl -y
sudo nala update
sudo nala install -y tmux most zsh watch htop build-essential mosh unzip python3-pip rsync git-lfs jq ssh-import-id gh

ssh-import-id-gh qnlbnsl
curl -fsSL https://tailscale.com/install.sh | sudo sh

pip3 install powerline-status
pip3 install yq

# Install my settings
make

# Finish remaining setup
nvm_setup
gpg_setup
gh_setup
docker_setup
golang_setup

# Install plugins and utilities
sudo chsh -s /usr/bin/zsh "${user}"
zsh -i -c zplug install
zsh -i -c go install github.com/owenthereal/ccat@latest
zsh -i -c go install github.com/creack/assumerole@latest

# Helps in general... Especially when coding in react
# Increasing max watchers to 65535
$maxfiles = "fs.file-max = 65535"
# Increasing max watchers. Each file watch consumes up to 1080 bytes.
# 524288 will be able to use up to 540MB
$maxwatches = "fs.inotify.max_user_watches=524288"

echo $maxfiles | sudo tee -a /etc/sysctl.conf
echo $maxwatches | sudo tee -a /etc/sysctl.conf
