#!/usr/bin/env bash

function setup_user() {
  user=$(whoami)
  if [ ! "${user}" = "root" ]; then
    echo "Granting sudoer nopassword to ${user}" >&2
    echo "${user} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/90-${user}-root"
  else
    options=(Yes No)
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

export -f setup_user