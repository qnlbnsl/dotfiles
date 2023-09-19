#!/usr/bin/env bash

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