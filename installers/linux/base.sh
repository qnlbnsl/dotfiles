#!/usr/bin/env bash

set -e

user=$(whoami)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Proxmox Specific
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  echo "We are using Proxmox"
  # Sync time
  sudo hwclock --hctosys
  # Use PVE Tools to setup proxmox
  bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
  echo "Please visit https://tteck.github.io/Proxmox/ for more tools"
fi

# Install sudo if needed
if ! hash sudo 2>/dev/null; then
  apt-get update
  apt-get install -y sudo
fi

sudo apt install -y git curl make gcc tmux mosh zsh unzip gzip ssh-import-id build-essential dialog

# Ask if the user wants to create a new user
dialog --yesno "Do you want to create a new user?" 7 60
response=$?
clear

if [ $response -eq 0 ]; then
  # Source the user creation script
  source "${script_dir}/shell_functions/setup_user.sh"
  create_new_user
  echo "Please exit and log in with the new user. Aborting the script."
  exit 0
fi

mkdir -p $HOME/.local/bin
# Define an associative array for package descriptions
declare -A descriptions=(
  ["shell"]="Shell Dotfiles"
  ["go"]="Go Language"
  ["golangci-lint"]="Go Linter"
  ["docker"]="Docker Container Engine"
  ["terraform"]="Infrastructure as Code Tool"
  ["github"]="Setup GitHub and GPG keys"
  ["locales"]="Setup locales for the system"
)

# Generate a checklist array for the main dialog
checklist=()
for key in "${!descriptions[@]}"; do
  checklist+=("$key" "${descriptions[$key]}" "off")
done

# Show main dialog menu and get user selections
user_choices=$(dialog --clear \
  --backtitle "Package Installation" \
  --no-cancel \
  --title "Select Packages to Install" \
  --checklist "Use SPACE to select packages and ENTER to confirm:" \
  20 60 10 \
  "${checklist[@]}" \
  2>&1 >/dev/tty)

clear

# Check if GitHub was selected and show sub-dialog if needed
if echo "$user_choices" | grep -q "github"; then
  # Define an associative array for GitHub-related tasks
  declare -A github_tasks=(
    ["github"]="Install GitHub CLI"
    ["github-login"]="Login to GitHub"
    ["gpg_setup"]="Create GPG Keys"
    ["upload_gpg_keys"]="Upload GPG Keys to GitHub"
  )

  # Generate a checklist array for the GitHub dialog
  github_checklist=()
  for key in "${!github_tasks[@]}"; do
    github_checklist+=("$key" "${github_tasks[$key]}" "off")
  done

  # Show GitHub dialog menu and get user selections
  github_choices=$(dialog --clear \
    --backtitle "GitHub Setup" \
    --no-cancel \
    --title "Select GitHub Tasks to Perform" \
    --checklist "Use SPACE to select tasks and ENTER to confirm:" \
    20 60 10 \
    "${github_checklist[@]}" \
    2>&1 >/dev/tty)

  clear

  # Handle GitHub task dependencies and login task switching
  if echo "$github_choices" | grep -q "upload_gpg_keys"; then
    github_choices="github github-login-gpg gpg_setup upload_gpg_keys"
  elif echo "$github_choices" | grep -q "gpg_setup"; then
    github_choices="github github-login gpg_setup"
  elif echo "$github_choices" | grep -q "github-login"; then
    github_choices="github github-login"
  fi

  # Add GitHub tasks to main user choices
  for choice in $github_choices; do
    user_choices+=" $choice"
  done
fi

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
echo "Done! Please reboot the system to apply changes orrrrrrr exit the ssh session and log back in."
