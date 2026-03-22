# common.mk — Shared targets for all platforms.
# Included by the root Makefile. Do not run directly.

# ── Symlinks ─────────────────────────────────────────────────────────
# Files in shell/ that get symlinked to ~/
# NOTE: .zshenv is handled separately per-platform (see ZSHENV_SRC).
LINKS_SRCS = .oh-my-zsh \
             .aliases \
             .android \
             .autoload \
             .editorconfig \
             .gitconfig \
             .gitignore.global \
             .p10k.zsh \
             .profile \
             .tmux.conf \
             .zprofile \
             .zshenv \
             .zshrc \
             .ssh/config \
             .zsh_functions \
             .config/sheldon/plugins.toml

LINKS_TARGETS = $(LINKS_SRCS:%=$(HOME)/%)
LINKS_CLEAN   = $(LINKS_SRCS:%=clean_link_%)

# Junk to nuke on 'make purge'.
PURGE_LIST = .cache .emacs.d .yarn .npm .node-gyp .elinks .apex .terraform.d .parallel \
             .psql_history .python_history .wget-hsts .node_repl_history \
             .yarnrc .zcompdump* .sudo_as_admin_successful .xsession-errors .lesshst \
             .config/yarn .texlive* .java .refresh .ssh_known_hosts .boto \
             .pm2 .pm2-dev .qt .nx .ipython .clang-tools .bash_logout .viminfo

# ── Default install (platforms extend this via additional install: lines)
install: $(LINKS_TARGETS) omz sheldon tpm nvm import_ssh_keys git-hide-local

# ── Clean / Purge ────────────────────────────────────────────────────
clean: $(LINKS_CLEAN) clean_.oh-my-zsh clean_.tpm clean_.nvm clean_.goroot \
       clean_golangci-lint clean_terraform clean_.sheldon

purge: clean
	cd $(HOME); $(RM) -r $(PURGE_LIST)

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: all install clean purge debug git-hide-local \
        omz clean_.oh-my-zsh sheldon clean_.sheldon \
        tpm clean_.tpm nvm clean_.nvm \
        go clean_.goroot golangci-lint clean_golangci-lint \
        terraform clean_terraform cargo clean_.cargo \
        import_ssh_keys import_ssh_keys_service \
        gitsetup clean_link_.gitconfig.local \
        github-login github-login-gpg \
        gpg_setup gpg_setup_export upload_gpg_keys git_gpg_update \
        clean_file_% clean_link_%

# ── Debug ────────────────────────────────────────────────────────────
debug:
	@echo "OS:            $(OS)"
	@echo "ARCH:          $(ARCH)"
	@echo "PLATFORM:      $(PLATFORM)"
	@echo "GREP_P:        $(GREP_P)"
	@echo "HOME:          $(HOME)"
	@echo "BASE_DIR:      $(BASE_DIR)"
	@echo "SHELL_DIR:     $(SHELL_DIR)"
	@echo "INSTALLER_DIR: $(INSTALLER_DIR)"
	@echo "ZSHENV_SRC:    $(ZSHENV_SRC)"

# ══════════════════════════════════════════════════════════════════════
#  Shell environment
# ══════════════════════════════════════════════════════════════════════

# ── oh-my-zsh + powerlevel10k ────────────────────────────────────────
omz: $(HOME)/.oh-my-zsh/oh-my-zsh.sh
$(HOME)/.oh-my-zsh/oh-my-zsh.sh:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) \
		|| git clone "https://anonymouse@github.com/robbyrussell/oh-my-zsh" $(dir $@)
	@[ -d $(dir $@)custom/themes/powerlevel10k ] \
		|| git clone --depth=1 "https://anonymouse@github.com/romkatv/powerlevel10k.git" $(dir $@)custom/themes/powerlevel10k
clean_.oh-my-zsh:
	$(RM) -r $(HOME)/.oh-my-zsh

# ── sheldon (plugin manager, installed via prebuilt binary) ──────────
sheldon: $(HOME)/.local/bin/sheldon
$(HOME)/.local/bin/sheldon:
	@mkdir -p $(dir $@)
	curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
		| bash -s -- --repo rossmacarthur/sheldon --to $(dir $@)
clean_.sheldon:
	$(RM) $(HOME)/.local/bin/sheldon

# ── tpm (tmux plugin manager) ───────────────────────────────────────
tpm: $(HOME)/.tmux/plugins/tpm/tpm
$(HOME)/.tmux/plugins/tpm/tpm:
	@[ -d $(dir $@) ] && (cd $(dir $@) && git pull) \
		|| git clone https://github.com/tmux-plugins/tpm $(dir $@)
clean_.tpm:
	$(RM) -r $(HOME)/.tmux/plugins/tpm

# ── nvm ──────────────────────────────────────────────────────────────
nvm: $(HOME)/.nvm
$(HOME)/.nvm:
	@[ -d $@ ] \
		&& (cd $@ && git fetch --tags origin && git checkout $$(git describe --abbrev=0 --tags --match "v[0-9]*" $$(git rev-list --tags --max-count=1))) \
		|| (git clone "https://anonymouse@github.com/nvm-sh/nvm" $@ \
		    && cd $@ && git checkout $$(git describe --abbrev=0 --tags --match "v[0-9]*" $$(git rev-list --tags --max-count=1)))
clean_.nvm:
	$(RM) -r $(HOME)/.nvm

# ══════════════════════════════════════════════════════════════════════
#  Dev tools (opt-in: make go, make terraform, etc.)
# ══════════════════════════════════════════════════════════════════════

# ── Go ───────────────────────────────────────────────────────────────
go: $(HOME)/.goroot
$(HOME)/.goroot: $(BASE_DIR)/versions/go
	@$(RM) -r $@ && mkdir -p $@
	@printf "\nInstalling Go $(shell cat $<) ($(OS)-$(ARCH))...\n"
	curl -sSL "https://go.dev/dl/go$(shell cat $<).$(OS)-$(ARCH).tar.gz" \
		| tar -xz --strip-components=1 -C $@
	@touch $@
clean_.goroot:
	$(RM) -r $(HOME)/.goroot
	@printf "\nTo clean Go module cache: sudo rm -rf $(HOME)/go/pkg/\n\n" >&2

# ── Terraform ────────────────────────────────────────────────────────
terraform: $(HOME)/.local/bin/terraform
$(HOME)/.local/bin/terraform: terraform.zip
	@mkdir -p $(dir $@)
	unzip -o $< -d $(dir $@)
	@touch $@
.INTERMEDIATE: terraform.zip
terraform.zip: $(BASE_DIR)/versions/terraform
	curl -sfL "https://releases.hashicorp.com/terraform/$(shell cat $<)/terraform_$(shell cat $<)_$(OS)_$(ARCH).zip" -o $@
clean_terraform:
	$(RM) $(HOME)/.local/bin/terraform

# ── golangci-lint ────────────────────────────────────────────────────
golangci-lint: $(HOME)/.local/bin/golangci-lint
$(HOME)/.local/bin/golangci-lint: $(BASE_DIR)/versions/golangci-lint
	@mkdir -p $(dir $@)
	curl -sfL "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" \
		| sh -s -- -b $(dir $@) v$(shell cat $<)
clean_golangci-lint:
	$(RM) $(HOME)/.local/bin/golangci-lint

# ── yq (YAML processor — standalone binary, works on all platforms) ──
.PHONY: yq
yq: $(HOME)/.local/bin/yq
$(HOME)/.local/bin/yq:
	@mkdir -p $(dir $@)
	curl -sfL "https://github.com/mikefarah/yq/releases/latest/download/yq_$(OS)_$(ARCH)" -o $@
	chmod +x $@

# ── Go tools (requires go to be installed) ───────────────────────────
.PHONY: go-tools
go-tools: go
	$(HOME)/.goroot/bin/go install github.com/owenthereal/ccat@latest
	$(HOME)/.goroot/bin/go install github.com/creack/assumerole@latest

# ── Cargo / Rust ─────────────────────────────────────────────────────
cargo: $(HOME)/.cargo/bin/cargo
$(HOME)/.cargo/bin/cargo:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
clean_.cargo:
	@echo "Run 'rustup self uninstall' to remove Rust."

# ══════════════════════════════════════════════════════════════════════
#  Symlinks
# ══════════════════════════════════════════════════════════════════════

# Generic rule: link shell dotfiles to ~/
$(HOME)/%: $(SHELL_DIR)/%
	@mkdir -p $(dir $@)
	ln -f -s $< $@

# OS-specific .zshenv (ZSHENV_SRC is set by platform .mk)
$(HOME)/.zshenv: $(ZSHENV_SRC)
	ln -f -s $< $@

# Remove symlinks only if they are still symlinks.
clean_link_%:
	@[ -L $(HOME)/$* ] && $(RM) $(HOME)/$* || true

clean_link_.ssh/config:
	@[ -L $(HOME)/.ssh/config ] && $(RM) $(HOME)/.ssh/config || true
clean_link_.config/sheldon/plugins.toml:
	@[ -L $(HOME)/.config/sheldon/plugins.toml ] && $(RM) $(HOME)/.config/sheldon/plugins.toml || true
clean_link_.zshenv:
	@[ -L $(HOME)/.zshenv ] && $(RM) $(HOME)/.zshenv || true
clean_link_.zsh_functions:
	@[ -L $(HOME)/.zsh_functions ] && $(RM) $(HOME)/.zsh_functions || true

# Remove a specific file from home: make clean_file_.foo
clean_file_%:
	$(RM) $(HOME)/$*

# ══════════════════════════════════════════════════════════════════════
#  SSH
# ══════════════════════════════════════════════════════════════════════

# Keep local edits to tracked files out of git status.
# Undo with: git update-index --no-skip-worktree <file>
git-hide-local:
	@if [ -d $(BASE_DIR)/.git ] && [ -f $(BASE_DIR)/.ssh/config ]; then \
		git -C $(BASE_DIR) update-index --skip-worktree .ssh/config; \
	fi

import_ssh_keys: $(HOME)/.ssh/authorized_keys
$(HOME)/.ssh/authorized_keys:
	@mkdir -p $(dir $@)
	curl -s https://github.com/qnlbnsl.keys >> $@

# systemd timer for auto-importing SSH keys (Linux only).
import_ssh_keys_service: /etc/systemd/system/import-ssh-keys.service /etc/systemd/system/import-ssh-keys.timer
	@systemctl daemon-reload
	@systemctl enable import-ssh-keys.timer
	@systemctl start import-ssh-keys.timer
	@echo "Service and Timer setup completed"

/etc/systemd/system/import-ssh-keys.service: $(SSH_DIR)/import-ssh-keys.service
	@ln -f -s $< $@

/etc/systemd/system/import-ssh-keys.timer: $(SSH_DIR)/import-ssh-keys.timer
	@ln -f -s $< $@

# ══════════════════════════════════════════════════════════════════════
#  GitHub / GPG
# ══════════════════════════════════════════════════════════════════════
GPG_QNLBNSL_KEY  = $(HOME)/.gpg_qnlbnsl_done
GPG_IMMERTEC_KEY  = $(HOME)/.gpg_immertec_done
EXPORT_QNLBNSL   = $(HOME)/public-qnlbnsl.pgp
EXPORT_IMMERTEC   = $(HOME)/public-immertec.pgp

# gh auth (requires github target from platform .mk to ensure gh is installed)
github-login: github
	@gh auth login

github-login-gpg: github
	@gh auth login -s write:gpg_key

# Git profile setup
gitsetup: $(HOME)/.gitconfig.local
$(HOME)/.gitconfig.local: $(SHELL_DIR)/.gitconfig.qnlbnsl
	ln -f -s $< $@
$(SHELL_DIR)/.gitconfig.qnlbnsl: git_gpg_update

clean: clean_link_.gitconfig.local

# GPG key generation
gpg_setup: $(GPG_QNLBNSL_KEY) $(GPG_IMMERTEC_KEY)

$(GPG_QNLBNSL_KEY):
	gpg --list-keys 'qnlbnsl@gmail.com' || gpg --generate-key --passphrase "" --batch $(GPG_TEMPLATES_DIR)/qnlbnsl
	@touch $@

$(GPG_IMMERTEC_KEY):
	gpg --list-keys 'kunal@immertec.com' || gpg --generate-key --batch $(GPG_TEMPLATES_DIR)/immertec
	@touch $@

# GPG key export
gpg_setup_export: $(EXPORT_QNLBNSL) $(EXPORT_IMMERTEC)

$(EXPORT_QNLBNSL): $(GPG_QNLBNSL_KEY)
	@gpg --output $@ --armor --export 'qnlbnsl@gmail.com'

$(EXPORT_IMMERTEC): $(GPG_IMMERTEC_KEY)
	@gpg --output $@ --armor --export 'kunal@immertec.com'

# Upload GPG keys to GitHub
upload_gpg_keys: $(EXPORT_QNLBNSL) $(EXPORT_IMMERTEC)
	gh gpg-key add $(EXPORT_QNLBNSL)
	gh gpg-key add $(EXPORT_IMMERTEC)
	rm -f $(EXPORT_QNLBNSL) $(EXPORT_IMMERTEC)

# Extract GPG key IDs and update gitconfig signing key
git_gpg_update: $(BASE_DIR)/.git_gpg_update
$(BASE_DIR)/.git_gpg_update:
	@key1=$$(gpg --list-secret-keys --keyid-format=long qnlbnsl@gmail.com | $(GREP_P) 'sec' | $(GREP_P) -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp $(GPG_TEMPLATES_DIR)/.gitconfig.qnlbnsl.template $(SHELL_DIR)/.gitconfig.qnlbnsl; \
	echo "  signingKey = $$key1" | tee -a $(SHELL_DIR)/.gitconfig.qnlbnsl; \
	key2=$$(gpg --list-secret-keys --keyid-format=long kunal@immertec.com | $(GREP_P) 'sec' | $(GREP_P) -o -P 'rsa4096.{0,17}' | cut -d/ -f2); \
	cp $(GPG_TEMPLATES_DIR)/.gitconfig.immertec.template $(SHELL_DIR)/.gitconfig.immertec; \
	echo "  signingKey = $$key2" | tee -a $(SHELL_DIR)/.gitconfig.immertec; \
	touch $@; \
	$(MAKE) gitsetup
