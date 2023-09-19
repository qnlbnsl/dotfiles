#!/usr/bin/env bash

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