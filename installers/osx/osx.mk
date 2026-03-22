# osx.mk — macOS (ARM64) specific targets.
# Included by the root Makefile.

ZSHENV_SRC = $(INSTALLER_DIR)/osx/.zshenv

BREW_PACKAGES := coreutils grep gnupg gh python3 asitop most tmux mosh yq

# ── Extend default install with macOS targets ────────────────────────
install: brew-packages cargo

# ── Phony targets ────────────────────────────────────────────────────
.PHONY: xcode brew-bootstrap brew-packages github

# ── Xcode Command Line Tools (run first on a fresh Mac) ─────────────
xcode:
	@xcode-select -p >/dev/null 2>&1 \
		&& echo "Xcode CLT already installed." \
		|| xcode-select --install

# ── Homebrew ─────────────────────────────────────────────────────────
brew-bootstrap: /opt/homebrew/bin/brew
/opt/homebrew/bin/brew:
	@echo "Installing Homebrew..."
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-packages: brew-bootstrap
	brew install $(BREW_PACKAGES)

# ── GitHub CLI (installed via Homebrew) ──────────────────────────────
github:
	@command -v gh >/dev/null 2>&1 \
		&& echo "GitHub CLI already installed." \
		|| brew install gh
