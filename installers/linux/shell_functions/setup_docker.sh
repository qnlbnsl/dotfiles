#!/usr/bin/env bash
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