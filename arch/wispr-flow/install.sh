#!/usr/bin/env bash
# Build Wispr Flow for Linux (github.com/wispr-flow-linux/wispr-flow-linux)
# from the newest Wispr Flow Windows installer and install it as the
# wispr-flow-appimage package. Run by `make arch-wispr`; see arch/README.md.
#
#   FORCE=1      rebuild and reinstall even if that version is installed
#   PINNED=1     build the version wispr-flow-linux pins (the one its patches
#                were last audited against) instead of the newest
#
# The newest installer can be ahead of the pin. If the build fails on it
# (a patch stops matching), this falls back to the pinned version.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
src=${WISPR_SRC:-$HOME/.cache/wispr-flow-linux}
repo=https://github.com/wispr-flow-linux/wispr-flow-linux.git
appdir=$src/build-linux/appimage/ai.wisprflow.WisprFlow.AppDir
# "<version> <wispr-flow-linux commit>" of the last newest-installer build that
# failed, so it isn't retried until wispr-flow-linux changes.
failed_file=$HOME/.cache/wispr-flow-linux.failed
pin=scripts/setup/installer-pin.sh

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf 'wispr-flow: %s\n' "$*" >&2; exit 1; }

# sudo when it can prompt (or needs no password), else a graphical pkexec prompt.
as_root() {
  if [[ -t 0 ]] || sudo -n true 2>/dev/null; then
    sudo "$@"
  else
    pkexec "$@"
  fi
}

# ── Build tools ──────────────────────────────────────────────────────
# command -> package; only missing ones are installed (never -Sy on Omarchy).
declare -A tools=(
  [git]=git [curl]=curl [7z]=7zip [wrestool]=icoutils [icotool]=icoutils
  [magick]=imagemagick [rsync]=rsync [node]=nodejs [npx]=npm
  [python3]=python [makepkg]=pacman [fakeroot]=fakeroot [wl-copy]=wl-clipboard
)
missing=()
for cmd in "${!tools[@]}"; do
  hash "$cmd" 2>/dev/null || missing+=("${tools[$cmd]}")
done
if ((${#missing[@]})); then
  mapfile -t missing < <(printf '%s\n' "${missing[@]}" | sort -u)
  log "Installing build tools: ${missing[*]}"
  if hash omarchy-pkg-add 2>/dev/null; then
    omarchy-pkg-add "${missing[@]}"
  else
    as_root pacman -S --noconfirm --needed "${missing[@]}"
  fi
fi

# ── Source ───────────────────────────────────────────────────────────
if [[ -d $src/.git ]]; then
  log "Updating $src"
  git -C "$src" fetch -q --depth 1 origin main
  git -C "$src" reset -q --hard FETCH_HEAD
else
  log "Cloning wispr-flow-linux into $src"
  mkdir -p "$(dirname "$src")"
  git clone -q --depth 1 "$repo" "$src"
fi
cd "$src"

pinned=$(sed -n "s/^WISPR_VERSION='\(.*\)'$/\1/p" "$pin")
[[ -n $pinned ]] || die "could not read WISPR_VERSION from $pin"

# Wrapper version from the newest release tag (v1.0.4+wispr1.6.957 -> 1.0.4),
# so package versions look like the AUR ones.
repo_ver=$(git ls-remote -q --tags --sort=-v:refname origin 'v*' |
  sed -n 's|.*refs/tags/v\([0-9][0-9.]*\)+.*|\1|p' | head -1)
repo_ver=${repo_ver:-0}

# ── Which Wispr Flow version ─────────────────────────────────────────
target=$pinned
resolved=
if [[ -z ${PINNED:-} ]]; then
  if resolved=$(scripts/setup/resolve-installer-url.sh 2>/dev/null) &&
    grep -q '^SHA256=.' <<<"$resolved"; then
    target=$(sed -n 's/^VERSION=//p' <<<"$resolved")
  else
    log "Could not resolve the newest installer (or it has no sha256); using pinned $pinned"
    resolved=
  fi
fi

installed=$(pacman -Q wispr-flow-appimage 2>/dev/null |
  sed -n 's/.*+wispr\([0-9.]*\)-.*/\1/p' || true)
if [[ $installed == "$target" && -z ${FORCE:-} ]]; then
  log "Wispr Flow $target is already installed (FORCE=1 to rebuild)"
  exit 0
fi

# Print the version inside a staged AppDir's app.asar.
asar_version() {
  python3 -I - "$appdir/usr/lib/wispr-flow/resources/app.asar" <<'EOF'
import json, struct, sys
with open(sys.argv[1], "rb") as f:
    f.seek(4); base = 8 + struct.unpack("<I", f.read(4))[0]
    f.seek(12); n = struct.unpack("<I", f.read(4))[0]
    entry = json.loads(f.read(n))["files"]["package.json"]
    f.seek(base + int(entry["offset"]))
    print(json.loads(f.read(entry["size"]))["version"])
EOF
}

# Build an AppDir for $1. Without appimagetool the maker stops after staging
# the AppDir, which is all the package needs.
build() {
  local version=$1
  git checkout -q -- "$pin"
  if [[ $version != "$pinned" ]]; then
    scripts/setup/write-installer-pin.sh <<<"$resolved" ||
      return 1
  fi
  # A tree extracted from another version makes build.sh stop.
  rm -rf extract build-linux/appimage
  log "Building Wispr Flow $version"
  ./build.sh --build appimage || return 1
  [[ -d $appdir && $(asar_version) == "$version" ]]
}

head=$(git rev-parse HEAD)
if [[ $target != "$pinned" && -z ${FORCE:-} &&
  $(cat "$failed_file" 2>/dev/null) == "$target $head" ]]; then
  log "Wispr Flow $target already failed to build at this wispr-flow-linux commit; using pinned $pinned"
  target=$pinned
  if [[ $installed == "$target" ]]; then
    log "Wispr Flow $target is already installed (FORCE=1 to rebuild)"
    exit 0
  fi
fi

if ! build "$target"; then
  [[ $target != "$pinned" ]] || die "build of Wispr Flow $pinned failed"
  echo "$target $head" >"$failed_file"
  log "Build of $target failed; falling back to the pinned $pinned"
  target=$pinned
  if [[ $installed == "$target" && -z ${FORCE:-} ]]; then
    git checkout -q -- "$pin"
    log "Wispr Flow $target is already installed (FORCE=1 to rebuild)"
    exit 0
  fi
  build "$target" || die "build of Wispr Flow $pinned failed"
fi
git checkout -q -- "$pin"

# ── Package ──────────────────────────────────────────────────────────
pkgdir=$(mktemp -d)
trap 'rm -rf "$pkgdir"' EXIT
sed -e "s|@PKGVER@|$repo_ver+wispr$target|" -e "s|@APPDIR@|$appdir|" \
  "$script_dir/PKGBUILD.in" >"$pkgdir/PKGBUILD"
log "Packaging wispr-flow-appimage $repo_ver+wispr$target"
(cd "$pkgdir" && makepkg -f --noconfirm >/dev/null)
pkg=$(ls "$pkgdir"/wispr-flow-appimage-*.pkg.tar.zst)

# ── Install ──────────────────────────────────────────────────────────
# A running instance can ignore SIGTERM and keep running from the replaced
# files, so make sure it's gone. pkill -x only: -f would match this script.
was_running=
if pgrep -x wispr-flow >/dev/null; then
  was_running=1
  log "Stopping Wispr Flow"
  pkill -x wispr-flow || true
  for _ in {1..15}; do
    pgrep -x wispr-flow >/dev/null || break
    sleep 1
  done
  pkill -9 -x wispr-flow || true
  pkill -9 -x wispr-flow-linu || true
  rm -f "$HOME/.config/Wispr Flow/SingletonLock"
fi

as_root pacman -U --noconfirm "$pkg"

if [[ -n $was_running && -n ${WAYLAND_DISPLAY:-} ]]; then
  log "Starting Wispr Flow"
  setsid -f wispr-flow >/dev/null 2>&1
fi

if [[ ! -e /etc/keyd/wispr-flow.conf ]]; then
  log "Run 'make arch-system' for the uinput/udev/keyd setup Wispr Flow needs, then restart it."
fi
log "Wispr Flow $target installed"
