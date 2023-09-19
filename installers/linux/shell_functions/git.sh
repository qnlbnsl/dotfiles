#!/usr/bin/env bash

function gh_setup() {
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