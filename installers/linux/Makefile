# All Targets: omz zplug tpm nvm go docker terraform golangci-lint install clean purge
USER ?= $(shell whoami)
HOME ?= $(shell [ -d "/Users/${USER}" ] && echo /Users/${USER} || echo /home/${USER})
PWD  ?= $(shell pwd)
RM   ?= rm -f
BASE_DIR := $(abspath $(PWD)/../..)
GPG_TEMPLATES_DIR := $(BASE_DIR)/gpg_templates
SHELL_DIR := $(BASE_DIR)/shell
SSH_DIR := $(BASE_DIR)/.ssh
ARCH=amd64
ifeq ($(shell uname),Linux)
OS=linux
else
OS=darwin
endif

LINKS_SRCS=	.oh-my-zsh	\
		.ssh/config	\
		.zsh_functions	\
		.editorconfig	\
		.gitconfig	\
		.p10k.zsh	\
		.tmux.conf	\
		.zprofile	\
		.zshenv		\
		.zshrc		\
		.config		\

LINKS_TARGETS = ${LINKS_SRCS:%=${HOME}/%}
LINKS_CLEAN   = ${LINKS_SRCS:%=clean_link_%}

# List of file/dirs to nuke when calling 'make purge'.
PURGE_LIST = .cache .emacs.d .yarn .npm .node-gyp .elinks .apex .terraform.d .parallel \
             .psql_history .python_history .wget-hsts .node_repl_history \
             .yarnrc .zcompdump* .sudo_as_admin_successful .xsession-errors .lesshst \
             .config/yarn .texlive* .java .refresh .ssh_known_hosts .boto \
             .sudo_as_admin_successful .pm2 .pm2-dev .qt .nx .ipython .clang-tools .bash_logout .viminfo

# Default to install target.
all: install
shell: install
install: omz sheldon tpm nvm import_ssh_keys
clean:   clean_.oh-my-zsh clean_.zplug clean_tpm clean_.nvm clean_goroot clean_docker clean_terraform clean_golangci-lint

######################################################################################################################################################
# Install tpm (tmux plugin manager)
tpm: ${HOME}/.tmux/plugins/tpm/tpm
${HOME}/.tmux/plugins/tpm/tpm:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone https://github.com/tmux-plugins/tpm $(dir $@)
clean_tpm:
	${RM} -r ${HOME}/.tmux/plugins/tpm

######################################################################################################################################################
# Install nvm so it is around when needed.
# The git command is taken from NVM github repository.
nvm: ${HOME}/.nvm

${HOME}/.nvm:
	@[ -d $@ ] && (cd $@ && git fetch --tags origin && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`) || git clone "https://anonymouse@github.com/nvm-sh/nvm" $@ && (cd $@ && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`)
clean_.nvm:
	${RM} -r ${HOME}/.nvm

######################################################################################################################################################
# Install go.
# The url is https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
go: ${HOME}/goroot
${HOME}/goroot: versions/go
	@${RM} -r $@ && mkdir $@
	@printf "\nDownloading from https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz\n"
	curl -sSL "https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz" | tar -xz -P --transform='s|^go|$@|'
	@touch $@
clean_goroot:
	${RM} -r ${HOME}/goroot
	@printf "\nTo cleanup go mod's cache, run:\n\n  sudo rm -rf ${HOME}/go/pkg/\n\n" >&2

######################################################################################################################################################
# Install docker-compose.
docker:
	curl -fsSL https://get.docker.com | bash
	sudo usermod -aG docker ${USER}
clean_docker:
	${RM} ${HOME}/.local/bin/docker-compose
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

######################################################################################################################################################
# Install golangci-lint.
golangci-lint: ${HOME}/.local/bin/golangci-lint
clean:   clean_golangci-lint
${HOME}/.local/bin/golangci-lint: versions/golangci-lint
	@mkdir -p $(dir $@)
	curl -sfL "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- -b $(dir $@) v$(shell cat $<)
clean_golangci-lint:
	${RM} ${HOME}/.local/bin/golangci-lint
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

######################################################################################################################################################
# Terraform
terraform: ${HOME}/.local/bin/terraform
${HOME}/.local/bin/terraform: terraform.zip
	unzip $<
	mv terraform $@
	touch $@
.INTERMEDIATE: terraform.zip
terraform.zip: versions/terraform
	@mkdir -p $(dir $@)
	curl -sfL "https://releases.hashicorp.com/terraform/$(shell cat $<)/terraform_$(shell cat $<)_${OS}_${ARCH}.zip" -o terraform.zip
clean_terraform:
	${RM} ${HOME}/.local/bin/terraform
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

######################################################################################################################################################
# Shell dotfiles
# Default the git profile to the .qnlbnsl one.
gitsetup: ${HOME}/.gitconfig.local
${HOME}/.gitconfig.local: ${SHELL_DIR}/.gitconfig.qnlbnsl
	ln -f -s $< $@
clean: clean_link_.gitconfig.local

# Install oh-my-zsh if not installed.
# Use anonymous@ to avoid matching any existing insteadOf url config.
# install: ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k
omz: ${HOME}/.oh-my-zsh/oh-my-zsh.sh
${HOME}/.oh-my-zsh/oh-my-zsh.sh:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone "https://anonymouse@github.com/robbyrussell/oh-my-zsh" $(dir $@)
	git clone --depth=1 "https://anonymouse@github.com/romkatv/powerlevel10k.git" $(dir $@)custom/themes/powerlevel10k
clean_.oh-my-zsh:
	${RM} -r ${HOME}/.oh-my-zsh

sheldon: ${HOME}/.local/bin/sheldon
${HOME}/.local/bin/sheldon:
	@mkdir -p $(dir $@)
	curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
clean_.sheldon:
	${RM} ${HOME}/.local/bin/sheldon
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

# Install zplug
zplug: ${HOME}/.zplug/init.zsh
${HOME}/.zplug/init.zsh:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone "https://anonymouse@github.com/zplug/zplug" $(dir $@)
clean_.zplug:
	${RM} -r ${HOME}/.zplug

# remove a specific file from home.. e.g. make clean_file_.zshrc
clean_file_%:
	${RM} ${HOME}/$*

# Place symlink from home to here.
install: ${LINKS_TARGETS}
${HOME}/%: ${SHELL_DIR}/%
	ln -f -s $< $@
# Remove the symlinks only if they are still symlink.
clean: ${LINKS_CLEAN}
clean_link_%:
	@[ -L ${HOME}/$* ] && ${RM} ${HOME}/$* || true

######################################################################################################################################################
# SSH
# Make sure we have a ~/.ssh dir for linkink ~/.ssh/config
${HOME}/.ssh/config: ${SSH_DIR}/config
	@mkdir -p $(dir $@)
	ln -f -s $< $@
clean_link_.ssh/config:
	@[ -L ${HOME}/.ssh/config ] && ${RM} ${HOME}/.ssh/config || true

import_ssh_keys: ${HOME}/.ssh/authorized_keys
${HOME}/.ssh/authorized_keys:
	curl -s https://github.com/qnlbnsl.keys >> $@

# Linking the import-ssh-keys.service file from ./.ssh/ to /etc/systemd/system/
import_ssh_keys_service: /etc/systemd/system/import-ssh-keys.service /etc/systemd/system/import-ssh-keys.timer
	@systemctl daemon-reload
	@systemctl enable import-ssh-keys.timer
	@systemctl start import-ssh-keys.timer
	@echo "Service and Timer setup completed"

/etc/systemd/system/import-ssh-keys.service: ${SSH_DIR}/import-ssh-keys.service
	@ln -f -s $< $@
	@echo "Linked service file"

/etc/systemd/system/import-ssh-keys.timer: ${SSH_DIR}/import-ssh-keys.timer
	@ln -f -s $< $@
	@echo "Linked timer file"

######################################################################################################################################################
## GIT
git:
	@echo "Installing gh..."
	@curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	@sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	@echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
	@sudo apt update && sudo apt install gh
	@bash -c 'if [ -x "$$(command -v gh)" ]; then \
		echo "Would you like to login to GitHub?"; \
		select answer in Yes No; do \
			case $$REPLY in \
				[yY][eE][sS] | [yY]) \
					gh auth login -s write:gpg_key; \
					echo "Would you like to generate GPG keys?"; \
					select answer in Yes No; do \
						case $$REPLY in \
							[yY][eE][sS] | [yY]) \
								@$(MAKE) gpg_setup; \
								@$(MAKE) upload_gpg_keys; \
								@$(MAKE) git_gpg_update; \
								exit 0; \
								;; \
							[nN][oO] | [nN]) \
								exit 0; \
								;; \
						esac; \
					done; \
					break; \
					;; \
				[nN][oO] | [nN]) \
					exit 0; \
					;; \
			esac; \
		done; \
	fi')

gpg_setup:
	@echo "Generating GPG keys..."
	gpg --generate-key --batch ${GPG_TEMPLATES_DIR}/qnlbnsl
	gpg --generate-key --batch ${GPG_TEMPLATES_DIR}/immertec
	@bash -c 'echo "Would you like to export the generated GPG keys?"; \
		select answer in Yes No; do \
			case $$REPLY in \
				[yY][eE][sS] | [yY]) \
					echo "Exporting qnlbnsl@gmail.com"; \
					gpg --output ~/public-qnlbnsl.pgp --armor --export 'qnlbnsl@gmail.com'; \
					echo "Exporting kunal@immertec.com"; \
					gpg --output ~/public-immertec.pgp --armor --export 'kunal@immertec.com'; \
					break; \
					;; \
				[nN][oO] | [nN]) \
					exit 0; \
					;; \
			esac; \
		done'

upload_gpg_keys:
	@echo "Uploading GPG keys to GitHub..."
	gh gpg-key import ~/public-qnlbnsl.pgp
	gh gpg-key import ~/public-immertec.pgp

git_gpg_update:
	key1=$$(gpg --list-secret-keys --keyid-format=long qnlbnsl@gmail.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp ${SHELL_DIR}/.gitconfig.qnlbnsl.template ${SHELL_DIR}/.gitconfig.qnlbnsl; \
	echo "  signingKey = $$key1" | tee -a ${SHELL_DIR}/.gitconfig.qnlbnsl; \
	$(MAKE) gitsetup
	key2=$$(gpg --list-secret-keys --keyid-format=long kunal@immertec.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp ${SHELL_DIR}/.gitconfig.immertec.template ${SHELL_DIR}/.gitconfig.immertec; \
	echo "  signingKey = $$key2" | tee -a ${SHELL_DIR}/.gitconfig.immertec

######################################################################################################################################################
# Setup locales
locales:
	@sudo locale-gen en_US.UTF-8 && \
  	export LC_ALL=C.UTF-8 && \
  	export LANG=C.UTF-8 && \
  	sudo EDITOR="sed -Ei ' \
    	s|locales/locales_to_be_generated=.+|locales/locales_to_be_generated=\"en_US.UTF-8 UTF-8\"|; \
    	s|locales/default_environment_locale=.+|locales/default_environment_locale=\"en_US.UTF-8\"| \
    	'" dpkg-reconfigure -f editor locales


######################################################################################################################################################
# Setup User
user:
	@bash -c 'source ${PWD}/shell_functions/setup_user.sh; setup_user'
######################################################################################################################################################
# Main targets.
install:
clean:

# Purge removes the common cache folder created by various tools.
purge: clean
	cd ${HOME}; ${RM} -r ${PURGE_LIST}

# Phony targets.
.PHONY: all install clean purge git import_ssh_keys
