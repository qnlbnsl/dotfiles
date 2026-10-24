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

# Only desktops get this as part of the default install.
ifneq (,$(wildcard /usr/bin/Hyprland))
install: arch-config
endif

.PHONY: arch-config arch-links arch-overview arch-overview-save arch-system

arch-config: arch-overview arch-links
	@hyprctl reload >/dev/null 2>&1 && hyprctl configerrors || true

# Symlink every file in arch/home, then arch/hosts/<host>/home (which wins), into ~.
# A regular file in the way is moved to <file>.bak.<timestamp> first.
arch-links:
	@for root in "$(ARCH_CFG_DIR)/home" "$(ARCH_HOST_DIR)/home"; do \
		[ -d "$$root" ] || continue; \
		(cd "$$root" && find . -type f) | while read -r f; do \
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

# After editing the QML in ~/.config/quickshell/overview, save the changes back here.
arch-overview-save:
	@git -C "$(OVERVIEW_DIR)" diff "$(OVERVIEW_COMMIT)" > "$(OVERVIEW_PATCH)"
	@echo "saved overview changes to arch/overview/macos.patch"

# Root-owned daemons (keyd, udev) read these, so they are copied rather than linked.
arch-system:
	@for root in "$(ARCH_CFG_DIR)/system" "$(ARCH_HOST_DIR)/system"; do \
		[ -d "$$root" ] || continue; \
		(cd "$$root" && find . -type f) | while read -r f; do \
			f="$${f#./}"; sudo install -Dm644 "$$root/$$f" "/$$f" && echo "installed /$$f"; \
		done; \
	done
	sudo udevadm control --reload
	@if systemctl is-active -q keyd; then \
		sudo systemctl restart keyd; \
		echo "keyd restarted: restart Wispr Flow too, or its helper stops hearing keys."; \
	fi
