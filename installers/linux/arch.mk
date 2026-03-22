# arch.mk — Arch Linux specific targets.
# Included by the root Makefile.

ZSHENV_SRC = $(INSTALLER_DIR)/linux/.zshenv

PACMAN_PACKAGES := zsh git curl make gcc tmux mosh unzip gzip openssh \
                   htop python python-pip rsync git-lfs jq github-cli gnupg most yq

# ── Extend default install with Arch targets ─────────────────────────
install: pacman-packages

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: pacman-packages github docker clean_docker omarchy \
        set-shell create-user

# ── Pacman packages ──────────────────────────────────────────────────
pacman-packages:
	sudo pacman -Syu --noconfirm --needed $(PACMAN_PACKAGES)

# ── GitHub CLI (available directly from pacman) ──────────────────────
github:
	@command -v gh >/dev/null 2>&1 \
		&& echo "GitHub CLI already installed." \
		|| sudo pacman -S --noconfirm --needed github-cli

# ── Docker ───────────────────────────────────────────────────────────
docker:
	sudo pacman -S --noconfirm --needed docker docker-compose
	sudo systemctl enable --now docker
	sudo usermod -aG docker $(USER)
clean_docker:
	sudo pacman -Rns --noconfirm docker docker-compose || true

# ── Set default shell to zsh ─────────────────────────────────────────
set-shell:
	sudo chsh -s /usr/bin/zsh $$(whoami)

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

# ── Omarchy (optional UI setup for Arch) ─────────────────────────────
# Customize this target for your omarchy/UI workflow.
# See: https://github.com/basecamp/omarchy
omarchy:
	@echo "Install omarchy UI targets here."
	@echo "Example: clone omarchy repo and run its installer."
