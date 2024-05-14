#!/usr/bin/env bash

set -e

# Function to create a new user with sudo permissions
create_new_user() {
  new_username=$(dialog --inputbox "Enter new username:" 8 40 2>&1 >/dev/tty)
  clear

  new_password=$(dialog --passwordbox "Enter password for $new_username:" 8 40 2>&1 >/dev/tty)
  clear

  new_password_confirm=$(dialog --passwordbox "Confirm password for $new_username:" 8 40 2>&1 >/dev/tty)
  clear

  if [ "$new_password" != "$new_password_confirm" ]; then
    echo "Passwords do not match. Aborting."
    exit 1
  fi

  # Create the new user and their home directory(-m), set their shell to bash(-s), and set their password
  sudo useradd -m -s /bin/bash "$new_username"
  echo "$new_username:$new_password" | sudo chpasswd
  sudo usermod -aG sudo "$new_username"
  echo "$new_username ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-$new_username-root"
  echo "User $new_username created and added to sudo group."
}

# Prompt for new user creation
create_new_user
