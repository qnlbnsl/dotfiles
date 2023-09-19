#!/usr/bin/env bash

set -e

user=$(whoami)

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

# Install sudo if needed
if ! hash sudo 2>/dev/null; then
  apt-get update
  apt-get install -y sudo
fi

sudo apt install -y git curl make gcc tmux mosh zsh unzip gzip ssh-import-id build-essential dialog

# Define an associative array for package descriptions
declare -A descriptions=(
  ["shell"]="Setup Everything for zsh"
  ["locales"]="Setup locales for the system"
  ["user"]="Create New User with sudoers permissions"
  ["git"]="Setup github and gpg keys"
  ["go"]="Go Language"
  ["docker"]="Docker Container Engine"
  ["terraform"]="Infrastructure as Code Tool"
  ["golangci-lint"]="Go Linter"
)

# Generate a checklist array for dialog
checklist=()
for key in "${!descriptions[@]}"; do
  checklist+=("$key" "${descriptions[$key]}" "off")
done

# Show dialog menu and get user selections
user_choices=$(dialog --clear \
  --backtitle "Package Installation" \
  --no-cancel \
  --title "Select Packages to Install" \
  --checklist "Use SPACE to select packages and ENTER to confirm:" \
  20 60 10 \
  "${checklist[@]}" \
  2>&1 >/dev/tty)

clear

# Handle user selections
for choice in $user_choices; do
  echo "Installing $choice..."
  make $choice
done

echo "Finishing up..."
# Helps in general... Especially when coding in react
# Increasing max watchers to 65535
maxfiles="fs.file-max = 65535"
# Increasing max watchers. Each file watch consumes up to 1080 bytes.
# 524288 will be able to use up to 540MB
maxwatches="fs.inotify.max_user_watches=524288"
echo $maxfiles | sudo tee -a /etc/sysctl.conf
echo $maxwatches | sudo tee -a /etc/sysctl.conf
sudo chsh -s /usr/bin/zsh "$(whoami)"
echo "Done!"
# finito