USER ?= $(shell whoami)
HOME ?= $(shell [ -d "/Users/${USER}" ] && echo /Users/${USER} || echo /home/${USER})
PWD  ?= $(shell pwd)
RM   ?= rm -f

ARCH=amd64
ifeq ($(shell uname),Linux)
OS=linux
else
OS=darwin
endif

LINKS_SRCS    =	 .config 	\
		.oh-my-zsh 	    \
		.ssh/config         \
		.zplug  	    \
		.zsh_functions 	    \
                .aspell.en.pws      \
                .aspell.en.prepl    \
		.editorconfig       \
                .gitconfig          \
                .p10k.zsh 	    \
		.tmux.conf          \
                .Xresources         \
		.zprofile	    \
                .zshenv             \
                .zshrc              \

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

# Default the git profile to the .qnlbnsl one.
gitsetup: ${HOME}/.gitconfig.local
${HOME}/.gitconfig.local: ${PWD}/shell/.gitconfig.qnlbnsl
	ln -f -s $< $@
clean: clean_link_.gitconfig.local

# Install oh-my-zsh if not installed.
# Use anonymous@ to avoid matching any existing insteadOf url config.
install: ${HOME}/.oh-my-zsh/oh-my-zsh.sh
# install: ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k
clean:   clean_.oh-my-zsh
${HOME}/.oh-my-zsh/oh-my-zsh.sh:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone "https://anonymouse@github.com/robbyrussell/oh-my-zsh" $(dir $@)
	git clone --depth=1 "https://anonymouse@github.com/romkatv/powerlevel10k.git" $(dir $@)custom/themes/powerlevel10k
clean_.oh-my-zsh:
	${RM} -r ${HOME}/.oh-my-zsh

# Install zplug
install: ${HOME}/.zplug/init.zsh
clean: clean_.zplug
${HOME}/.zplug/init.zsh:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone "https://anonymouse@github.com/zplug/zplug" $(dir $@)
clean_.zplug:
	${RM} -r ${HOME}/.zplug

# Install tpm (tmux plugin manager)
install: ${HOME}/.tmux/plugins/tpm/tpm
${HOME}/.tmux/plugins/tpm/tpm:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) || git clone https://github.com/tmux-plugins/tpm $(dir $@)
clean: clean_tpm
clean_tpm:
	${RM} -r ${HOME}/.tmux/plugins/tpm

# Install nvm so it is around when needed.
# The git command is taken from NVM github repository.
install: ${HOME}/.nvm
clean:   clean_.nvm
${HOME}/.nvm:
	@[ -d $@ ] && (cd $@ && git fetch --tags origin && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`) || git clone "https://anonymouse@github.com/nvm-sh/nvm" $@ && (cd $@ && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`)
clean_.nvm:
	${RM} -r ${HOME}/.nvm

# On OSX, those are installed via brew.
ifeq (${OS},linux)
# install: ${HOME}/goroot
go: ${HOME}/goroot
clean:   clean_goroot

# install: docker
clean:   clean_docker
endif

# Install go.
# The url is https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
${HOME}/goroot: versions/go
	@${RM} -r $@ && mkdir $@
	@printf "\nDownloading from https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz\n"
	curl -sSL "https://go.dev/dl/go$(shell cat $<).${OS}-${ARCH}.tar.gz" | tar -xz -P --transform='s|^go|$@|'
	@touch $@
clean_goroot:
	${RM} -r ${HOME}/goroot
	@printf "\nTo cleanup go mod's cache, run:\n\n  sudo rm -rf ${HOME}/go/pkg/\n\n" >&2

# Install docker-compose.
docker:
	curl -fsSL https://get.docker.com | bash

clean_docker:
	${RM} ${HOME}/.local/bin/docker-compose
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

# Install golangci-lint.
install: ${HOME}/.local/bin/golangci-lint
clean:   clean_golangci-lint
${HOME}/.local/bin/golangci-lint: versions/golangci-lint
	@mkdir -p $(dir $@)
	curl -sfL "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- -b $(dir $@) v$(shell cat $<)
clean_golangci-lint:
	${RM} ${HOME}/.local/bin/golangci-lint
	@rmdir ${HOME}/.local/bin ${HOME}/.local 2> /dev/null || true

install: ${HOME}/.local/bin/terraform
clean:   clean_terraform
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

clean_file_%:
	${RM} ${HOME}/$*

# Place symlink from home to here.
install: ${LINKS_TARGETS}
${HOME}/%: ${PWD}/shell/%
	ln -f -s $< $@
# Remove the symlinks only if they are still symlink.
clean: ${LINKS_CLEAN}
clean_link_%:
	@[ -L ${HOME}/$* ] && ${RM} ${HOME}/$* || true

# Make sure we have a ~/.ssh dir for linkink ~/.ssh/config
${HOME}/.ssh/config: ${PWD}/.ssh/config
	@mkdir -p $(dir $@)
	ln -f -s $< $@
clean_link_.ssh/config:
	@[ -L ${HOME}/.ssh/config ] && ${RM} ${HOME}/.ssh/config || true

# Enable xterm-truecolor support.
install: ${HOME}/.terminfo
clean:   clean_.terminfo
${HOME}/.terminfo: shell/xterm-truecolor.terminfo
	tic -x -o ${HOME}/.terminfo $<
# Remove .terminfo only if xterm-truecolor was the only entry.
clean_.terminfo:
	@${RM} -r ${HOME}/.terminfo

# Main targets.
install:
clean:

# Purge removes the common cache folder created by various tools.
purge: clean
	cd ${HOME}; ${RM} -r ${PURGE_LIST}

# Phony targets.
.PHONY: all install clean purge update ubuntu
