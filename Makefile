# Dotfiles — clone, make, done.
#
# Targets:
#   make                Shell env + OS packages (default)
#   make go             Install Go
#   make terraform      Install Terraform
#   make golangci-lint  Install golangci-lint
#   make cargo          Install Rust/Cargo
#   make docker         Install Docker (Linux only)
#   make github         Install GitHub CLI
#   make gpg_setup      Generate GPG keys
#   make gitsetup       Link gitconfig.local
#   make clean          Remove installed components
#   make purge          Remove + nuke caches
#   make debug          Print detected OS/arch/paths

# Default target — must be first.
all: install
.DEFAULT_GOAL := all

# ── OS / Arch Detection ─────────────────────────────────────────────
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
  OS       := darwin
  ARCH     := arm64
  GREP_P   := ggrep
  PLATFORM := osx
else ifeq ($(UNAME_S),Linux)
  OS       := linux
  GREP_P   := grep
  ifeq ($(UNAME_M),x86_64)
    ARCH := amd64
  else ifeq ($(UNAME_M),aarch64)
    ARCH := arm64
  else
    ARCH := $(UNAME_M)
  endif
  DISTRO_ID := $(shell . /etc/os-release 2>/dev/null && echo $$ID)
  ifneq (,$(filter $(DISTRO_ID),arch manjaro endeavouros))
    PLATFORM := arch
  else
    PLATFORM := debian
  endif
else
  $(error Unsupported OS: $(UNAME_S))
endif

# ── Paths ────────────────────────────────────────────────────────────
USER          ?= $(shell whoami)
HOME          ?= $(shell [ -d "/Users/$(USER)" ] && echo /Users/$(USER) || echo /home/$(USER))
BASE_DIR      := $(shell git -C $(dir $(realpath $(firstword $(MAKEFILE_LIST)))) rev-parse --show-toplevel)
INSTALLER_DIR := $(BASE_DIR)/installers
GPG_TEMPLATES_DIR := $(BASE_DIR)/git_gpg_templates
SHELL_DIR     := $(BASE_DIR)/shell
SSH_DIR       := $(BASE_DIR)/.ssh
RM            ?= rm -f

# ── Platform-specific targets (sets ZSHENV_SRC, package targets, etc.)
ifeq ($(PLATFORM),osx)
  include $(INSTALLER_DIR)/osx/osx.mk
else ifeq ($(PLATFORM),arch)
  include $(INSTALLER_DIR)/linux/arch.mk
else
  include $(INSTALLER_DIR)/linux/debian.mk
endif

# ── Common targets (uses vars set above) ─────────────────────────────
include $(BASE_DIR)/common.mk
