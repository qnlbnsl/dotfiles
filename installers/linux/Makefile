USER ?= $(shell whoami)
HOME ?= $(shell [ -d "/Users/${USER}" ] && echo /Users/${USER} || echo /home/${USER})
MAKEFILE_DIR := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
BASE_DIR := $(abspath $(MAKEFILE_DIR)/../..)
GPG_TEMPLATES_DIR := $(BASE_DIR)/git_gpg_templates
SHELL_DIR := $(BASE_DIR)/shell
SSH_DIR := $(BASE_DIR)/.ssh
RM   ?= rm -f
ARCH=amd64
ifeq ($(shell uname),Linux)
	OS=linux
else
	OS=darwin
endif

LINKS_SRCS=	.oh-my-zsh		\
			.aliases		\
			.android 		\
			.autoload		\
			.editorconfig	\
			.gitconfig		\
			.gitignore.global \
			.p10k.zsh		\
			.profile		\
			.tmux.conf		\
			.zprofile		\
			.zshenv			\
			.zshrc			\
			.ssh/config		\
			.zsh_functions	\
			.config/sheldon/plugins.toml

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
clean:   clean_.oh-my-zsh clean_.tpm clean_.nvm clean_.goroot clean_docker clean_terraform clean_golangci-lint

# Purge removes the common cache folder created by various tools.
purge: clean
	cd ${HOME}; ${RM} -r ${PURGE_LIST}

# Phony targets.
.PHONY: all shell install clean purge \
		check_docker docker clean_docker \
        gitsetup clean_link_.gitconfig.local \
        import_ssh_keys import_ssh_keys_service \
        omz clean_.oh-my-zsh sheldon clean_.sheldon \
        tpm clean_.tpm nvm clean_.nvm go clean_.goroot \
        golangci-lint clean_golangci-lint terraform clean_terraform \
        github github-login github-login-gpg gpg_setup gpg_setup_export upload_gpg_keys git_gpg_update \
        locales clean_file_% clean_link_%


######################################################################################################################################################
# Install tpm (tmux plugin manager)
tpm: ${HOME}/.tmux/plugins/tpm/tpm
${HOME}/.tmux/plugins/tpm/tpm:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone https://github.com/tmux-plugins/tpm $(dir $@)
clean_.tpm:
	${RM} -r ${HOME}/.tmux/plugins/tpm

######################################################################################################################################################
# Install nvm so it is around when needed.
# The git command is taken from NVM github repository.
nvm: ${HOME}/.nvm

${HOME}/.nvm:
	@[ -d $@ ] && (cd $@ && git fetch --tags origin && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`) \
	|| git clone "https://anonymouse@github.com/nvm-sh/nvm" $@ && \
	(cd $@ && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`)
clean_.nvm:
	${RM} -r ${HOME}/.nvm

######################################################################################################################################################
###################################################################### TOOLS #########################################################################
######################################################################################################################################################
# Install GO to ~/goroot
# The url is https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
go: ${HOME}/.goroot
${HOME}/.goroot: ${BASE_DIR}/versions/go
	@${RM} -r $@ && mkdir $@
	@printf "\nDownloading from https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz\n"
	curl -sSL "https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz" | tar -xz -P --transform='s|^go|$@|'
	@touch $@
clean_.goroot:
	${RM} -r ${HOME}/.goroot
	@printf "\nTo cleanup go mod's cache, run:\n\n  sudo rm -rf ${HOME}/go/pkg/\n\n" >&2

######################################################################################################################################################
# Install Docker.
# Check for Docker command
check_docker: .check_docker
.check_docker:
	@if command -v docker > /dev/null 2>&1; then \
		echo >&2 "Docker is installed."; \
		touch "@"; \
	else \
		echo "Docker is required but it's not installed."; \
	fi

# Install docker-compose.
docker: check_docker
	@if ! [ -f /tmp/docker_installed ]; then \
		sudo sh shell_functions/docker.sh; \
		sudo usermod -aG docker ${USER}; \
	fi
clean_docker:
	@sudo apt-get remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

clean_.check_docker:
	${RM} .check_docker 

######################################################################################################################################################
# Install golangci-lint.
golangci-lint: ${HOME}/.local/bin/golangci-lint
${HOME}/.local/bin/golangci-lint: ${BASE_DIR}/versions/golangci-lint
	@mkdir -p $(dir $@)
	curl -sfL "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- -b $(dir $@) v$(shell cat $<)
clean:   clean_golangci-lint
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
terraform.zip: ${BASE_DIR}/versions/terraform
	@mkdir -p $(dir $@)
	curl -sfL "https://releases.hashicorp.com/terraform/$(shell cat $<)/terraform_$(shell cat $<)_${OS}_${ARCH}.zip" -o terraform.zip
clean_terraform:
	${RM} ${HOME}/.local/bin/terraform
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

######################################################################################################################################################
##################################################################### DOTFILES #######################################################################
######################################################################################################################################################
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

# remove a specific file from home.. e.g. make clean_file_.zshrc
clean_file_%:
	${RM} ${HOME}/$*

######################################################################################################################################################
################################################################### LINKS ############################################################################
######################################################################################################################################################
# Place symlink from home to here.
install: ${LINKS_TARGETS}
${HOME}/%: ${SHELL_DIR}/%
	ln -f -s $< $@
# Remove the symlinks only if they are still symlink.
clean: ${LINKS_CLEAN}
clean_link_%:
	@[ -L ${HOME}/$* ] && ${RM} ${HOME}/$* || true

# Make sure we have a ~/.ssh dir for linking ~/.ssh/config
${HOME}/.ssh/config: ${SSH_DIR}/config
	@mkdir -p $(dir $@)
	ln -f -s $< $@
clean_link_.ssh/config:
	@[ -L ${HOME}/.ssh/config ] && ${RM} ${HOME}/.ssh/config || true

# Ensure directories are created for .zsh_functions
${HOME}/.zsh_functions: ${SHELL_DIR}/.zsh_functions
	@mkdir -p $(dir $@)
	ln -f -s $< $@
clean_link_.zsh_functions:
	@[ -L ${HOME}/.zsh_functions ] && ${RM} ${HOME}/.zsh_functions || true

# Ensure directories are created for .config/sheldon/plugins.toml
${HOME}/.config/sheldon/plugins.toml: ${SHELL_DIR}/.config/sheldon/plugins.toml
	@mkdir -p $(dir $@)
	ln -f -s $< $@
clean_link_.config/sheldon/plugins.toml:
	@[ -L ${HOME}/.config/sheldon/plugins.toml ] && ${RM} ${HOME}/.config/sheldon/plugins.toml || true


${HOME}/.gitconfig.qnlbnsl: 

######################################################################################################################################################
##################################################################### SSH ############################################################################
######################################################################################################################################################
# Import SSH keys from GitHub
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
####################################################### GITHUB #######################################################################################
######################################################################################################################################################
# Default the git profile to the .qnlbnsl one.
gitsetup: ${HOME}/.gitconfig.local
${HOME}/.gitconfig.local: ${SHELL_DIR}/.gitconfig.qnlbnsl
	ln -f -s $< $@
${SHELL_DIR}/.gitconfig.qnlbnsl: git_gpg_update
	
clean: clean_link_.gitconfig.local



# Define paths to important files
SOURCES_LIST=/etc/apt/sources.list.d/github-cli.list
KEYRING=/usr/share/keyrings/githubcli-archive-keyring.gpg
GPG_QNLBNSL_KEY = ${HOME}/.gpg_qnlbnsl_done
GPG_IMMERTEC_KEY = ${HOME}/.gpg_immertec_done
EXPORT_QNLBNSL_PROXY = ${HOME}/public-qnlbnsl.pgp
EXPORT_IMMERTEC_PROXY = ${HOME}/public-immertec.pgp
GPG_KEYS_UPLOADED = ${HOME}/.gpg_keys_uploaded
GIT_GPG_UPDATED = ${HOME}/.git_gpg_updated

github: $(SOURCES_LIST) $(KEYRING)
	@echo "Checking if GitHub CLI is already installed..."
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "Installing gh..."; \
		sudo apt update && sudo apt install gh; \
	else \
		echo "GitHub CLI is already installed."; \
	fi

# Create or update the sources list if it does not exist
$(SOURCES_LIST): $(KEYRING)
	@echo "Adding GitHub CLI package repository..."
	@echo "deb [arch=$$(dpkg --print-architecture) signed-by=$(KEYRING)] https://cli.github.com/packages stable main" | sudo tee $@ >/dev/null

# Ensure the GPG keyring is up-to-date
$(KEYRING):
	@echo "Installing GitHub CLI archive keyring..."
	@curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=$@
	@sudo chmod go+r $@

github-login: github	
	@gh auth login		

github-login-gpg: github	
	@gh auth login -s write:gpg_key		

# Generate GPG keys
gpg_setup: $(GPG_QNLBNSL_KEY) $(GPG_IMMERTEC_KEY)

$(GPG_QNLBNSL_KEY):
	@gpg --list-keys 'qnlbnsl@gmail.com' || gpg --generate-key --batch ${GPG_TEMPLATES_DIR}/qnlbnsl
	@touch $@

$(GPG_IMMERTEC_KEY):
	@gpg --list-keys 'kunal@immertec.com' || gpg --generate-key --batch ${GPG_TEMPLATES_DIR}/immertec
	@touch $@

# Export GPG keys
gpg_setup_export: $(EXPORT_QNLBNSL_PROXY) $(EXPORT_IMMERTEC_PROXY)

$(EXPORT_QNLBNSL_PROXY): $(GPG_QNLBNSL_KEY)
	@gpg --output $@ --armor --export 'qnlbnsl@gmail.com'
	@echo "Exported qnlbnsl@gmail.com"

$(EXPORT_IMMERTEC_PROXY): $(GPG_IMMERTEC_KEY)
	@gpg --output $@ --armor --export 'kunal@immertec.com'
	@echo "Exported kunal@immertec.com"

upload_gpg_keys: $(EXPORT_QNLBNSL_PROXY) $(EXPORT_IMMERTEC_PROXY)
	@echo "Uploading GPG keys to GitHub..."
	gh gpg-key add $(EXPORT_QNLBNSL_PROXY) 
	gh gpg-key add $(EXPORT_IMMERTEC_PROXY)
	rm -rf $(EXPORT_QNLBNSL_PROXY)
	rm -rf $(EXPORT_IMMERTEC_PROXY)

git_gpg_update: .git_gpg_update
.git_gpg_update:
	@key1=$$(gpg --list-secret-keys --keyid-format=long qnlbnsl@gmail.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp ${GPG_TEMPLATES_DIR}/.gitconfig.qnlbnsl.template ${SHELL_DIR}/.gitconfig.qnlbnsl; \
	echo "  signingKey = $$key1" | tee -a ${SHELL_DIR}/.gitconfig.qnlbnsl; \
	key2=$$(gpg --list-secret-keys --keyid-format=long kunal@immertec.com | grep 'sec' | grep -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp ${GPG_TEMPLATES_DIR}/.gitconfig.immertec.template ${SHELL_DIR}/.gitconfig.immertec; \
	echo "  signingKey = $$key2" | tee -a ${SHELL_DIR}/.gitconfig.immertec; \
	touch $@; \
	$(MAKE) gitsetup

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

