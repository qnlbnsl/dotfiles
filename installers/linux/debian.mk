# debian.mk — Debian/Ubuntu specific targets.
# Included by the root Makefile.

ZSHENV_SRC = $(INSTALLER_DIR)/linux/.zshenv

APT_PACKAGES := zsh git curl make gcc build-essential tmux mosh unzip gzip \
                htop python3 python3-pip rsync git-lfs jq gnupg most ssh-import-id

# ── Extend default install with Debian targets ──────────────────────
install: apt-packages

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: apt-packages github docker clean_docker locales \
        set-shell sysctl-tune pve-setup create-user

# ── APT packages ─────────────────────────────────────────────────────
apt-packages:
	sudo apt-get update
	sudo apt-get install -y $(APT_PACKAGES)

# ── GitHub CLI (needs keyring + apt repo on Debian) ──────────────────
GH_KEYRING := /usr/share/keyrings/githubcli-archive-keyring.gpg
GH_SOURCES := /etc/apt/sources.list.d/github-cli.list

github: $(GH_SOURCES) $(GH_KEYRING)
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "Installing GitHub CLI..."; \
		sudo apt-get update && sudo apt-get install -y gh; \
	else \
		echo "GitHub CLI already installed."; \
	fi

$(GH_SOURCES): $(GH_KEYRING)
	@echo "Adding GitHub CLI package repository..."
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=$(GH_KEYRING)] https://cli.github.com/packages stable main" \
		| sudo tee $@ >/dev/null

$(GH_KEYRING):
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=$@
	sudo chmod go+r $@

# ── Docker ───────────────────────────────────────────────────────────
docker:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Installing Docker..."; \
		curl -fsSL https://get.docker.com | sudo sh; \
		sudo usermod -aG docker $(USER); \
	else \
		echo "Docker already installed."; \
	fi
clean_docker:
	sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ── Locales ──────────────────────────────────────────────────────────
locales:
	@sudo locale-gen en_US.UTF-8 && \
	export LC_ALL=C.UTF-8 && \
	export LANG=C.UTF-8 && \
	sudo EDITOR="sed -Ei ' \
		s|locales/locales_to_be_generated=.+|locales/locales_to_be_generated=\"en_US.UTF-8 UTF-8\"|; \
		s|locales/default_environment_locale=.+|locales/default_environment_locale=\"en_US.UTF-8\"| \
		'" dpkg-reconfigure -f editor locales

# ── Set default shell to zsh ─────────────────────────────────────────
set-shell:
	sudo chsh -s /usr/bin/zsh $$(whoami)

# ── Tune sysctl (file watchers, max open files) ─────────────────────
sysctl-tune:
	@echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf
	@echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p

# ── Proxmox VE detection and setup ──────────────────────────────────
pve-setup:
	@if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then \
		echo "Proxmox detected. Running post-install setup..."; \
		sudo hwclock --hctosys; \
		bash -c "$$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"; \
	else \
		echo "Not a Proxmox host."; \
	fi

# ── Create user with sudo access ────────────────────────────────────
# Usage: make create-user USERNAME=newuser
create-user:
	@if [ -z "$(USERNAME)" ]; then \
		echo "Usage: make create-user USERNAME=<name>"; \
		exit 1; \
	fi
	sudo adduser $(USERNAME)
	echo "$(USERNAME) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-$(USERNAME)-root
