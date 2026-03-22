#!/usr/bin/env bash

set -e

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

# Proxmox detection
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  echo "Proxmox detected."
  make -C "$repo_root" pve-setup
fi

# Bootstrap: install sudo + minimal deps needed before make can run.
if ! hash sudo 2>/dev/null; then
  apt-get update
  apt-get install -y sudo
fi
sudo apt-get install -y git curl make dialog

# User creation (if running as root)
if [[ $(whoami) == "root" ]]; then
  dialog --yesno "Do you want to create a new user?" 7 60 && {
    source "${script_dir}/shell_functions/setup_user.sh"
    create_new_user
    echo "Please exit and log in with the new user. Then re-run this script."
    exit 0
  } || true
  clear
fi

mkdir -p "$HOME/.local/bin"

# TUI for selecting make targets
declare -A descriptions=(
  ["install"]="Shell + packages (default)"
  ["go"]="Go language"
  ["golangci-lint"]="Go linter"
  ["docker"]="Docker"
  ["terraform"]="Terraform"
  ["github"]="Setup GitHub CLI"
  ["locales"]="Setup locales"
  ["sysctl-tune"]="Tune fs watchers / max files"
)

checklist=()
for key in "${!descriptions[@]}"; do
  checklist+=("$key" "${descriptions[$key]}" "off")
done

user_choices=$(dialog --clear \
  --backtitle "Dotfiles Setup" \
  --no-cancel \
  --title "Select targets to install" \
  --checklist "Use SPACE to select, ENTER to confirm:" \
  20 60 10 \
  "${checklist[@]}" \
  2>&1 >/dev/tty)

clear

# GitHub sub-dialog
if echo "$user_choices" | grep -q "github"; then
  declare -A github_tasks=(
    ["github"]="Install GitHub CLI"
    ["github-login"]="Login to GitHub"
    ["gpg_setup"]="Generate GPG keys"
    ["upload_gpg_keys"]="Upload keys to GitHub"
  )

  github_checklist=()
  for key in "${!github_tasks[@]}"; do
    github_checklist+=("$key" "${github_tasks[$key]}" "off")
  done

  github_choices=$(dialog --clear \
    --backtitle "GitHub Setup" \
    --no-cancel \
    --title "Select GitHub Tasks" \
    --checklist "Use SPACE to select, ENTER to confirm:" \
    20 60 10 \
    "${github_checklist[@]}" \
    2>&1 >/dev/tty)

  clear

  # Resolve dependencies
  if echo "$github_choices" | grep -q "upload_gpg_keys"; then
    github_choices="github github-login-gpg gpg_setup upload_gpg_keys"
  elif echo "$github_choices" | grep -q "gpg_setup"; then
    github_choices="github github-login gpg_setup"
  elif echo "$github_choices" | grep -q "github-login"; then
    github_choices="github github-login"
  fi
  user_choices+=" $github_choices"
fi

# Run selected targets via root Makefile
for choice in $user_choices; do
  echo "==> make $choice"
  make -C "$repo_root" "$choice"
done

# Always set zsh as default shell
make -C "$repo_root" set-shell
echo "Done! Log out and back in (or reboot) to apply changes."
