# arch/arch.mk — personal desktop config for Arch/Omarchy: Hyprland overrides,
# trackpad gestures, the macOS-style workspace overview and keyd/udev fixes.
# Included by installers/linux/arch.mk. See arch/README.md.

ARCH_CFG_DIR    := $(BASE_DIR)/arch
ARCH_HOST       ?= $(shell hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null)
ARCH_HOST_DIR   := $(ARCH_CFG_DIR)/hosts/$(ARCH_HOST)
OVERVIEW_DIR    := $(HOME)/.config/quickshell/overview
OVERVIEW_PATCH  := $(ARCH_CFG_DIR)/overview/macos.patch
OVERVIEW_URL    := $(shell sed -n 's/^url=//p' $(ARCH_CFG_DIR)/overview/UPSTREAM)
OVERVIEW_COMMIT := $(shell sed -n 's/^commit=//p' $(ARCH_CFG_DIR)/overview/UPSTREAM)

# keyd backs the Wispr Flow setup in arch-system; the rest is the macOS look
# (Inter UI font, WhiteSur icons, macOS cursor), see README "macOS look".
ARCH_PACKAGES     := keyd inter-font
ARCH_AUR_PACKAGES := whitesur-icon-theme apple_cursor
ARCH_THEME        := macos-graphite
AUR_ADD           := $(if $(OMARCHY),omarchy-pkg-aur-add,yay -S --noconfirm --needed --)

# Only desktops get this as part of the default install.
ifneq (,$(wildcard /usr/bin/Hyprland))
install: arch-config arch-wispr arch-system arch-theme
endif

.PHONY: arch-config arch-vm-serve arch-links arch-overview arch-overview-save arch-packages \
        arch-secureboot arch-system arch-theme arch-vm arch-wispr

# Secure Boot (own keys + Microsoft's) and TPM2 auto-unlock of the LUKS root. Run
# repeatedly; each run does the next step. Not part of `make install`. See
# arch/secureboot/setup.sh.
arch-secureboot:
	@bash "$(ARCH_CFG_DIR)/secureboot/setup.sh"

# Windows 11 VM with the RTX A1000 passed through, viewed with Looking Glass
# (mainpc only, not part of `make install`). See arch/vm/setup.sh.
arch-vm: arch-system arch-links
	@bash "$(ARCH_CFG_DIR)/vm/setup.sh"

# Serve arch/vm/windows to the Windows VM (only on the host-to-VM network) so its scripts
# can be installed from inside Windows. Ctrl+C when done.
arch-vm-serve:
	@echo "In an administrator PowerShell in Windows, run:"
	@echo "  iwr http://192.168.122.1:8765/install-lg-screens.ps1 -UseBasicParsing | iex"
	@python3 -m http.server 8765 --bind 192.168.122.1 --directory "$(ARCH_CFG_DIR)/vm/windows"

arch-packages:
	@$(PKG_ADD) $(ARCH_PACKAGES) || { $(STALE_DB_HINT); }
	@$(AUR_ADD) $(ARCH_AUR_PACKAGES)

# Apply the macOS theme unless it's already the current one. Packages first: the
# theme's icons.theme and the theme-set hook (font, cursor) need them installed.
arch-theme: arch-packages arch-links
	@if [ "$$(cat $(HOME)/.local/state/omarchy/current/theme.name 2>/dev/null)" = "$(ARCH_THEME)" ]; then \
		echo "theme $(ARCH_THEME) already set"; \
	else \
		omarchy theme set $(ARCH_THEME); \
	fi

arch-config: arch-overview arch-links
	@hyprctl reload >/dev/null 2>&1 && hyprctl configerrors || true

# Symlink every file (or symlink, e.g. a theme's wallpaper) in arch/home, then
# arch/hosts/<host>/home (which wins), into ~.
# A regular file in the way is moved to <file>.bak.<timestamp> first.
arch-links:
	@for root in "$(ARCH_CFG_DIR)/home" "$(ARCH_HOST_DIR)/home"; do \
		[ -d "$$root" ] || continue; \
		(cd "$$root" && find . -type f -o -type l) | while read -r f; do \
			f="$${f#./}"; dst="$(HOME)/$$f"; \
			mkdir -p "$$(dirname "$$dst")"; \
			if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
				mv "$$dst" "$$dst.bak.$$(date +%s)"; echo "backed up ~/$$f"; \
			fi; \
			ln -sfn "$$root/$$f" "$$dst"; echo "linked ~/$$f"; \
		done; \
	done

# Clone upstream quickshell-overview at the pinned commit and apply our macOS patch.
arch-overview:
	@if [ ! -d "$(OVERVIEW_DIR)/.git" ]; then \
		git clone -q "$(OVERVIEW_URL)" "$(OVERVIEW_DIR)" && \
		git -C "$(OVERVIEW_DIR)" checkout -q -b macos "$(OVERVIEW_COMMIT)" && \
		echo config.json >> "$(OVERVIEW_DIR)/.git/info/exclude"; \
	fi
	@if git -C "$(OVERVIEW_DIR)" apply --check "$(OVERVIEW_PATCH)" 2>/dev/null; then \
		git -C "$(OVERVIEW_DIR)" apply "$(OVERVIEW_PATCH)" && echo "applied macos.patch"; \
	elif git -C "$(OVERVIEW_DIR)" apply --reverse --check "$(OVERVIEW_PATCH)" 2>/dev/null; then \
		echo "macos.patch already applied"; \
	else \
		echo "macos.patch does not apply cleanly; see git -C $(OVERVIEW_DIR) status" >&2; exit 1; \
	fi

# After editing the QML in ~/.config/quickshell/overview, save the changes (new files too) back here.
arch-overview-save:
	@git -C "$(OVERVIEW_DIR)" add -A
	@git -C "$(OVERVIEW_DIR)" diff --cached "$(OVERVIEW_COMMIT)" > "$(OVERVIEW_PATCH)"
	@echo "saved overview changes to arch/overview/macos.patch"

# Root-owned daemons (keyd, udev) read these, so they are copied rather than linked.
arch-system: arch-packages
	@for root in "$(ARCH_CFG_DIR)/system" "$(ARCH_HOST_DIR)/system"; do \
		[ -d "$$root" ] || continue; \
		(cd "$$root" && find . -type f) | while read -r f; do \
			f="$${f#./}"; mode=644; [ -x "$$root/$$f" ] && mode=755; \
			sudo install -Dm$$mode "$$root/$$f" "/$$f" && echo "installed /$$f"; \
		done; \
	done
	sudo udevadm control --reload
	@# modules-load.d only applies at boot; load uinput now and re-run its udev rule.
	sudo modprobe uinput
	sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput
	@if systemctl is-active -q keyd; then \
		sudo systemctl restart keyd; \
	else \
		sudo systemctl enable --now keyd; \
	fi
	@echo "keyd (re)started: restart Wispr Flow too (pkill -x wispr-flow), or its helper stops hearing keys."

# Build Wispr Flow from the newest Wispr installer and install it as a package
# (falls back to wispr-flow-linux's pinned version if the newest doesn't build).
# No-op when that version is already installed; FORCE=1 rebuilds, PINNED=1 builds the pin.
arch-wispr:
	@"$(ARCH_CFG_DIR)/wispr-flow/install.sh"
