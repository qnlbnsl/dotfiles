# Dotfiles

Cross-platform dotfiles for macOS (ARM64), Debian/Ubuntu, and Arch Linux.

## Quickstart

```sh
git clone https://github.com/qnlbnsl/dotfiles ~/.dotfiles
cd ~/.dotfiles
make
```

On a fresh **Debian/Ubuntu** box (as root or with sudo):

```sh
git clone https://github.com/qnlbnsl/dotfiles ~/.dotfiles
chmod +x ~/.dotfiles/installers/linux/base.sh
~/.dotfiles/installers/linux/base.sh
```

## What `make` installs

The default `install` target sets up:

- **zsh** with oh-my-zsh + Powerlevel10k theme
- **sheldon** plugin manager (zsh-autosuggestions, zsh-syntax-highlighting, etc.)
- **tpm** (tmux plugin manager)
- **nvm** (Node version manager, lazy-loaded)
- **Symlinks** from `shell/` to `~/` (.zshrc, .gitconfig, .tmux.conf, etc.)
- **SSH keys** imported from GitHub
- **OS packages** via Homebrew (macOS), apt (Debian), or pacman (Arch)

## Additional targets

| Target | Description |
|--------|-------------|
| `make shell` | Symlink `shell/` dotfiles and OS-specific `.zshenv` into `~/` |
| `make go` | Install Go (version from `versions/go`) |
| `make go-tools` | Install ccat + assumerole via `go install` |
| `make terraform` | Install Terraform (version from `versions/terraform`) |
| `make golangci-lint` | Install golangci-lint (version from `versions/golangci-lint`) |
| `make cargo` | Install Rust via rustup |
| `make yq` | Install yq YAML processor |
| `make docker` | Install Docker (Linux only) |
| `make github` | Install GitHub CLI |
| `make github-login` | Authenticate with GitHub |
| `make gpg_setup` | Generate GPG keys |
| `make upload_gpg_keys` | Upload GPG keys to GitHub |
| `make gitsetup` | Render git profiles from templates and link `~/.gitconfig.local` (GPG signing if keys exist) |
| `make debug` | Print detected OS, arch, and paths |
| `make clean` | Remove installed components |
| `make purge` | Clean + nuke caches |

### Debian/Ubuntu only

| Target | Description |
|--------|-------------|
| `make locales` | Setup en_US.UTF-8 locale |
| `make sysctl-tune` | Increase file watchers and max open files |
| `make pve-setup` | Proxmox VE post-install setup |
| `make set-shell` | Set default shell to zsh |
| `make create-user USERNAME=foo` | Create user with sudo NOPASSWD |

### Arch Linux only

| Target | Description |
|--------|-------------|
| `make set-shell` | Set default shell to zsh |
| `make create-user USERNAME=foo` | Create user with sudo NOPASSWD |
| `make omarchy` | Omarchy UI setup (customize in `arch.mk`) |

## Updating tool versions

```sh
echo "1.22.3" > versions/go && make go
echo "1.14.5" > versions/terraform && make terraform
echo "1.58.1" > versions/golangci-lint && make golangci-lint
```

## Structure

```
.dotfiles/
├── Makefile              Root dispatcher (auto-detects OS + arch)
├── common.mk             Shared targets
├── installers/
│   ├── osx/
│   │   ├── osx.mk        macOS: Homebrew, ARM64
│   │   └── .zshenv        macOS-specific env
│   └── linux/
│       ├── debian.mk      Debian/Ubuntu: apt, gh repo, docker
│       ├── arch.mk         Arch: pacman, omarchy
│       ├── base.sh         Interactive TUI installer for Debian
│       └── .zshenv         Linux-specific env
├── shell/                 Shared dotfiles (symlinked to ~/)
├── versions/              Pinned tool versions
├── git_gpg_templates/     GPG key templates
└── .ssh/                  SSH config
```

## Dependencies

- git, curl, make (bootstrap)
- Everything else is installed by `make`

## Thanks

Thanks to [@creack](https://github.com/creack) for the original repo structure.
