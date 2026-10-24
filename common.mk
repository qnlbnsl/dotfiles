# common.mk — Shared targets for all platforms.
# Included by the root Makefile. Do not run directly.

# ── Symlinks ─────────────────────────────────────────────────────────
# Files in shell/ that get symlinked to ~/
# NOTE: .zshenv is OS-specific (ZSHENV_SRC) and is not in shell/.
LINKS_SRCS = .aliases \
             .android \
             .autoload \
             .editorconfig \
             .gitconfig \
             .gitignore.global \
             .p10k.zsh \
             .profile \
             .tmux.conf \
             .zprofile \
             .zshrc \
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
# .ssh/config lives at repo .ssh/config (not shell/.ssh); see $(HOME)/.ssh/config rule below.
install: shell $(HOME)/.ssh/config omz sheldon tpm nvm import_ssh_keys git-hide-local agents

# ── Clean / Purge ────────────────────────────────────────────────────
clean: $(LINKS_CLEAN) clean_link_.zshenv clean_link_.ssh/config \
       clean_.oh-my-zsh clean_.tpm clean_.nvm clean_.goroot \
       clean_golangci-lint clean_terraform clean_.sheldon

purge: clean
	cd $(HOME); $(RM) -r $(PURGE_LIST)

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: all install shell clean purge debug git-hide-local \
        omz clean_.oh-my-zsh sheldon clean_.sheldon \
        tpm clean_.tpm nvm clean_.nvm \
        go clean_.goroot golangci-lint clean_golangci-lint \
        terraform clean_terraform cargo clean_.cargo \
        import_ssh_keys import_ssh_keys_service \
        gitsetup git_gpg_update clean_link_.gitconfig.local \
        github-login github-login-gpg \
        gpg_setup gpg_setup_export upload_gpg_keys \
        agents claude-code clean_claude-code codex-cli clean_codex-cli \
        founder-repos founder-os clean_founder-os \
        clean_file_% clean_link_%

# ── Debug ────────────────────────────────────────────────────────────
debug:
	@echo "OS:            $(OS)"
	@echo "ARCH:          $(ARCH)"
	@echo "PLATFORM:      $(PLATFORM)"
	@echo "OMARCHY:       $(or $(OMARCHY),no)"
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

# Phony so this does not collide with the repo's shell/ directory.
# Always relink: make timestamps cannot tell "regular file" from "correct symlink",
# and a stock ~/.profile would otherwise block the link.
shell:
	@for f in $(LINKS_SRCS); do \
		mkdir -p "$(HOME)/$$(dirname "$$f")"; \
		$(RM) -r "$(HOME)/$$f"; \
		ln -s "$(SHELL_DIR)/$$f" "$(HOME)/$$f"; \
		echo "linked ~/$$f"; \
	done
	@$(RM) -r "$(HOME)/.zshenv"
	@ln -s "$(ZSHENV_SRC)" "$(HOME)/.zshenv"
	@echo "linked ~/.zshenv"
	@$(MAKE) gitsetup

# Generic rule: link a single shell dotfile to ~/ (e.g. make ~/.zshrc)
$(HOME)/%: $(SHELL_DIR)/%
	@mkdir -p $(dir $@)
	@$(RM) -r $@
	ln -s $< $@

# SSH config is tracked at $(BASE_DIR)/.ssh/config, not under shell/
$(HOME)/.ssh/config: $(SSH_DIR)/config
	@mkdir -p $(dir $@)
	@$(RM) -r $@
	ln -s $< $@

# OS-specific .zshenv (ZSHENV_SRC is set by platform .mk)
$(HOME)/.zshenv: $(ZSHENV_SRC)
	@$(RM) -r $@
	ln -s $< $@

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

# Git profiles from templates. GPG is optional:
#   keys present  -> gpgsign on + signingKey
#   keys missing  -> gpgsign off, still link identity
#   ~/.gitconfig.qnlbnsl   -> shell/.gitconfig.qnlbnsl
#   ~/.gitconfig.immertec  -> shell/.gitconfig.immertec
#   ~/.gitconfig.local     -> ~/.gitconfig.qnlbnsl   (setgit qnlbnsl|immertec)
RENDER_GITCONFIG := $(GPG_TEMPLATES_DIR)/render-gitconfig.sh

git_gpg_update:
	@bash $(RENDER_GITCONFIG) \
		$(GPG_TEMPLATES_DIR)/.gitconfig.qnlbnsl.template \
		qnlbnsl@gmail.com \
		$(SHELL_DIR)/.gitconfig.qnlbnsl
	@bash $(RENDER_GITCONFIG) \
		$(GPG_TEMPLATES_DIR)/.gitconfig.immertec.template \
		kunal@immertec.com \
		$(SHELL_DIR)/.gitconfig.immertec

gitsetup: git_gpg_update
	@$(RM) -r $(HOME)/.gitconfig.qnlbnsl $(HOME)/.gitconfig.immertec $(HOME)/.gitconfig.local
	ln -s $(SHELL_DIR)/.gitconfig.qnlbnsl $(HOME)/.gitconfig.qnlbnsl
	ln -s $(SHELL_DIR)/.gitconfig.immertec $(HOME)/.gitconfig.immertec
	ln -s $(HOME)/.gitconfig.qnlbnsl $(HOME)/.gitconfig.local
	@echo "linked ~/.gitconfig.local -> ~/.gitconfig.qnlbnsl"
	@echo "switch with: setgit qnlbnsl | setgit immertec"

clean: clean_link_.gitconfig.local clean_link_.gitconfig.qnlbnsl clean_link_.gitconfig.immertec

# GPG key generation, then re-render git profiles so signing keys are picked up.
gpg_setup: $(GPG_QNLBNSL_KEY) $(GPG_IMMERTEC_KEY)
	@$(MAKE) gitsetup

$(GPG_QNLBNSL_KEY):
	gpg --list-keys 'qnlbnsl@gmail.com' || gpg --generate-key --pinentry-mode loopback --passphrase "" --batch $(GPG_TEMPLATES_DIR)/qnlbnsl
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

# Upload GPG keys to GitHub, then fill+link git profiles (old git.sh did this).
upload_gpg_keys: $(EXPORT_QNLBNSL) $(EXPORT_IMMERTEC)
	gh gpg-key add $(EXPORT_QNLBNSL)
	gh gpg-key add $(EXPORT_IMMERTEC)
	rm -f $(EXPORT_QNLBNSL) $(EXPORT_IMMERTEC)
	$(MAKE) gitsetup

# ── Agents ───────────────────────────────────────────────────────────
# Founder OS ships as native plugins for Claude Code, Codex and Cursor -- not as
# loose skill links. The marketplace stays GitHub-backed so that the native
# marketplace-update path keeps working; $(FOUNDER_OS_DIR) is the checkout the
# installer runs FROM, and Codex and Cursor load it directly. Claude therefore
# runs the published version while Codex/Cursor run the working one. That drift
# is deliberate: it is where changes are made before they are pushed. The cursor
# lane is pure file wiring (a symlink plus ~/.cursor/hooks.json) and needs no
# Cursor binary, so it is safe over remote ssh.
PROJECTS_DIR     ?= $(HOME)/projects
FOUNDER_OS_REPO  ?= git@github.com:qnlbnsl/founder-os.git
FOUNDER_REPO     ?= git@github.com:qnlbnsl/founder.git
FOUNDER_OS_MARKET?= qnlbnsl/founder-os
FOUNDER_OS_DIR   := $(PROJECTS_DIR)/founder-os
FOUNDER_DIR      := $(PROJECTS_DIR)/founder
# Lanes handed to founder-os' own installer. hermes is deliberately absent; it
# installs itself in isolation.
FOUNDER_OS_LANES ?= claude codex cursor

agents: claude-code codex-cli founder-os

# Claude Code, native build. Never hand-link $(HOME)/.local/bin/claude here: the
# installer owns that symlink, and a foreign one stops it pruning old versions.
claude-code: $(HOME)/.local/bin/claude
$(HOME)/.local/bin/claude:
	curl -fsSL https://claude.ai/install.sh | bash
clean_claude-code:
	$(RM) $(HOME)/.local/bin/claude
	$(RM) -r $(HOME)/.local/share/claude

# Codex CLI, standalone build (no node runtime). Removes only the package cache;
# auth.json and config.toml under ~/.codex are left alone.
codex-cli: $(HOME)/.local/bin/codex
$(HOME)/.local/bin/codex:
	curl -fsSL https://chatgpt.com/codex/install.sh | sh
clean_codex-cli:
	$(RM) $(HOME)/.local/bin/codex
	$(RM) -r $(HOME)/.codex/packages

# Working checkouts. Cloned, never pulled: a rebase here is the owner's call.
founder-repos: $(FOUNDER_OS_DIR)/.git $(FOUNDER_DIR)/.git
$(FOUNDER_OS_DIR)/.git:
	@mkdir -p $(PROJECTS_DIR)
	git clone $(FOUNDER_OS_REPO) $(FOUNDER_OS_DIR)
$(FOUNDER_DIR)/.git:
	@mkdir -p $(PROJECTS_DIR)
	git clone $(FOUNDER_REPO) $(FOUNDER_DIR)

# Register the marketplace, then run founder-os' own installer for every lane.
# The installer is idempotent, needs no sudo, and installs no MCP servers or
# toolchains -- core's `provision` skill does that at first use.
# Keyed on the install registry the installer itself writes, so a routine
# `make install` is a no-op once set up. To re-run after changing founder-os,
# call its installer directly or `make clean_founder-os agents`.
founder-os: $(HOME)/.config/founder-os/install.json
$(HOME)/.config/founder-os/install.json: export PATH := $(HOME)/.local/bin:$(PATH)
$(HOME)/.config/founder-os/install.json: founder-repos claude-code codex-cli
	@command -v python3 >/dev/null 2>&1 \
		&& python3 -c 'import sys; sys.exit(sys.version_info < (3,11))' \
		|| { echo "founder-os needs python3 3.11+ on PATH" >&2; exit 1; }
	@claude plugin marketplace list --json 2>/dev/null | grep -q '"name": *"founder-os"' \
		|| claude plugin marketplace add $(FOUNDER_OS_MARKET)
	$(FOUNDER_OS_DIR)/scripts/install.sh $(FOUNDER_OS_LANES)
# Unregisters and forgets the install; leaves both checkouts on disk.
clean_founder-os: export PATH := $(HOME)/.local/bin:$(PATH)
clean_founder-os:
	-claude plugin marketplace remove founder-os
	$(RM) -r $(HOME)/.config/founder-os
	$(RM) $(HOME)/.cursor/plugins/local/founder-os-core

