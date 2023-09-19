#!/usr/bin/env bash

function setup_locales() {
  sudo locale-gen en_US.UTF-8
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8

  sudo EDITOR='sed -Ei "
    s|locales/locales_to_be_generated=.+|locales/locales_to_be_generated=\"en_US.UTF-8 UTF-8\"|;
    s|locales/default_environment_locale=.+|locales/default_environment_locale=\"en_US.UTF-8\"|
    "' dpkg-reconfigure -f editor locales
}

export -f setup_locales