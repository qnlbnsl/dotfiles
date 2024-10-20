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

setup_qemu_agent() {
  echo "Should i install qemu-guest-agent? "
  options=(Yes No)
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
    prompt="Is this the correct username:"
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
    PS3=""
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
gpg_setup() {
  options=(Yes No)
  echo "Would you like to generate GPG keys?"
  select answer in "${options[@]}"; do
    case $REPLY in
    [yY][eE][sS] | [yY])
      gpg --generate-key --batch qnlbnsl
      gpg --generate-key --batch immertec
      echo "Would you like to export the generated GPG Key?"
      select answer in "${options[@]}"; do
        case $REPLY in
        [yY][eE][sS] | [yY])
          echo "Exporting qnlbnsl@gmail.com"
          gpg --output ~/public-qnlbnsl.pgp --armor --export 'qnlbnsl@gmail.com'
          echo "Exporting kunal@immertec.com"
          gpg --output ~/public-immertec.pgp --armor --export 'kunal@immertec.com'
          break
          ;;
        [nN][oO] | [nN]) return ;;
        esac
      done
      break
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
git_gpg_update() {
  key1=$(gpg --list-secret-keys --keyid-format=long qnlbnsl@gmail.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2)
  cp shell/.gitconfig.qnlbnsl.template shell/.gitconfig.qnlbnsl
  echo "  signingKey = $key1" | tee -a shell/.gitconfig.qnlbnsl
  make gitsetup
  key2=$(gpg --list-secret-keys --keyid-format=long kunal@immertec.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2)
  cp shell/.gitconfig.immertec.template shell/.gitconfig.immertec
  echo "  signingKey = $key2" | tee -a shell/.gitconfig.immertec
}
gh_setup() {
  options=(Yes No)
  echo "Would you like to login to github?"
  select answer in "${options[@]}"; do
    case $REPLY in
    [yY][eE][sS] | [yY])
      gh auth login -s write:gpg_key
      echo "Would you like add the GPG key to github?"
      select answer in "${options[@]}"; do
        case $REPLY in
        [yY][eE][sS] | [yY])
          gh gpg-key add ~/public-qnlbnsl.pgp
          gh gpg-key add ~/public-immertec.pgp
          rm ~/public-qnlbnsl.pgp
          rm ~/public-immertec.pgp
          git_gpg_update
          break
          ;;
        [nN][oO] | [nN]) return ;;
        esac
      done
      break
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done

}
docker_setup() {
  options=(Yes No)
  echo "Would you like to install docker?"
  select answer in "${options[@]}"; do
    case $REPLY in
    [yY][eE][sS] | [yY])
      make docker
      break
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
golang_setup() {
  options=(Yes No)
  echo "Would you like to install golang?"
  select answer in "${options[@]}"; do
    case $REPLY in
    [yY][eE][sS] | [yY])
      make go
      zsh -i -c "go install github.com/owenthereal/ccat@latest"
      zsh -i -c "go install github.com/creack/assumerole@latest"
      break
      ;;
    [nN][oO] | [nN]) return ;;
    esac
  done
}
# android_setup() {
#   mkdir ~/tools
#   mkdir ~/tools/android
#   mkdir ~/tools/android/android-sdk
#   cp -r cmdline-tools ~/tools/android/android-sdk
#   # sdkmanager "platform-tools" "platforms;android-29"
#   # sdkmanager "build-tools;32.0.0"
# }
update_fs() {
  # Helps in general... Especially when coding in react
  # Increasing max watchers to 65535
  maxfiles="fs.file-max = 65535"
  # Increasing max watchers. Each file watch consumes up to 1080 bytes.
  # 524288 will be able to use up to 540MB
  maxwatches="fs.inotify.max_user_watches=524288"
  echo $maxfiles | sudo tee -a /etc/sysctl.conf
  echo $maxwatches | sudo tee -a /etc/sysctl.conf
}
# Pulls keyrings for github cli and nala.
# TODO: remove curl dependency
setup_keyrings

sudo apt-get update
sudo apt-get install -y make gcc tmux mosh zsh unzip gzip ssh-import-id build-essential
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
  sudo apt-get install -y watch htop unzip python3-pip rsync git-lfs jq gh
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
sudo apt-get upgrade -y
