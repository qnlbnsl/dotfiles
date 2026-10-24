# arch.mk — Arch Linux (and Omarchy) specific targets.
# Included by the root Makefile.
#
# Omarchy pins every package to a snapshot mirror and upgrades only through
# `omarchy update`; a pacman hook (00-omarchy-update-guard) blocks direct
# `pacman -Syu`. So on Omarchy these targets:
#   - never sync or upgrade (-Sy/-Syu): install missing packages from the
#     current db with --needed, so nothing Omarchy ships gets bumped
#   - never remove packages Omarchy ships (e.g. docker)
#   - leave Omarchy-owned system config alone (/etc/sysctl.d, docker group)

ZSHENV_SRC = $(INSTALLER_DIR)/linux/.zshenv

# Omarchy 4+ ships its helpers in /usr/bin (package); older releases used ~/.local/share/omarchy.
OMARCHY_PKG_ADD := $(firstword $(wildcard /usr/bin/omarchy-pkg-add \
                                          /usr/share/omarchy/bin/omarchy-pkg-add \
                                          $(HOME)/.local/share/omarchy/bin/omarchy-pkg-add))
OMARCHY := $(if $(or $(filter omarchy,$(DISTRO_ID)),$(OMARCHY_PKG_ADD)),1,)

# omarchy-pkg-add calls sibling helpers by name, so keep its dir on PATH.
ifneq (,$(OMARCHY_PKG_ADD))
  export PATH := $(patsubst %/,%,$(dir $(OMARCHY_PKG_ADD))):$(PATH)
  PKG_ADD := $(OMARCHY_PKG_ADD)
else
  PKG_ADD := sudo pacman -S --noconfirm --needed --
endif

# go-yq is mikefarah/yq (same as `make yq`); the `yq` package is the python jq wrapper.
PACMAN_PACKAGES := zsh git curl make gcc tmux mosh unzip gzip openssh \
                   htop python python-pip rsync git-lfs jq github-cli gnupg most go-yq dialog

STALE_DB_HINT := echo "Package install failed. If pacman got a 404, the local db is stale: run 'omarchy update' and retry." >&2; exit 1

# ── Extend default install with Arch targets ─────────────────────────
install: pacman-packages

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: pacman-packages github docker clean_docker locales \
        set-shell sysctl-tune create-user

# ── Pacman packages ──────────────────────────────────────────────────
pacman-packages:
ifeq ($(OMARCHY),1)
	@echo "Omarchy detected: installing missing packages only (upgrades go through 'omarchy update')."
	@$(PKG_ADD) $(PACMAN_PACKAGES) || { $(STALE_DB_HINT); }
else
	sudo pacman -Syu --noconfirm --needed $(PACMAN_PACKAGES)
endif

# ── GitHub CLI (available directly from pacman) ──────────────────────
github:
	@command -v gh >/dev/null 2>&1 \
		&& echo "GitHub CLI already installed." \
		|| $(PKG_ADD) github-cli

# ── Docker ───────────────────────────────────────────────────────────
# Omarchy ships docker with docker.socket enabled and keeps users out of the
# docker group on purpose (it is root-equivalent); access goes via sudo/polkit.
docker:
	@$(PKG_ADD) docker docker-compose || { $(STALE_DB_HINT); }
ifeq ($(OMARCHY),1)
	sudo systemctl enable --now docker.socket
	@echo "For sudoless docker on Omarchy run: omarchy-setup-security-sudoless-docker"
else
	sudo systemctl enable --now docker
	sudo usermod -aG docker $(USER)
endif
clean_docker:
ifeq ($(OMARCHY),1)
	@echo "Refusing: docker ships with Omarchy and its tooling depends on it." >&2; exit 1
else
	sudo pacman -Rns --noconfirm docker docker-compose || true
endif

# ── Locales ──────────────────────────────────────────────────────────
# Uncomments en_US.UTF-8 in locale.gen; only writes locale.conf if missing.
locales:
	sudo sed -i 's/^#\s*\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
	sudo locale-gen
	@[ -f /etc/locale.conf ] || echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf

# ── Set default shell to zsh ─────────────────────────────────────────
# Omarchy's own scripts are bash and keep working; ~/.bashrc is left untouched.
set-shell:
	sudo chsh -s /usr/bin/zsh $$(whoami)

# ── Tune sysctl (file watchers) ─────────────────────────────────────
# fs.file-max is not set: the kernel default on Arch is already far above 65535.
sysctl-tune:
ifeq ($(OMARCHY),1)
	@echo "Omarchy already sets fs.inotify.max_user_watches (/etc/sysctl.d/90-omarchy-file-watchers.conf)."
else
	echo "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/90-dotfiles-file-watchers.conf
	sudo sysctl --system
endif

# ── Create user with sudo access ────────────────────────────────────
# Usage: make create-user USERNAME=newuser
create-user:
	@if [ -z "$(USERNAME)" ]; then \
		echo "Usage: make create-user USERNAME=<name>"; \
		exit 1; \
	fi
	sudo useradd -m -G wheel -s /usr/bin/zsh $(USERNAME)
	sudo passwd $(USERNAME)
	echo "$(USERNAME) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-$(USERNAME)-root

# ── Personal desktop config (Hyprland, gestures, overview, keyd) ────
include $(BASE_DIR)/arch/arch.mk
