#!/usr/bin/env bash
# Render a git profile from a template.
# If a secret key exists for EMAIL, enable gpgsign and set signingKey.
# Otherwise leave GPG off (gpgsign=false, no -S / signed tags).
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 TEMPLATE EMAIL DEST" >&2
  exit 2
fi

template=$1
email=$2
dest=$3

key=""
if command -v gpg >/dev/null 2>&1; then
  key=$(gpg --list-secret-keys --with-colons "$email" 2>/dev/null \
    | awk -F: '/^sec:/ {print $5; exit}' || true)
fi

awk -v key="$key" '
  BEGIN { gpg = (key != "") }
  /^[[:space:]]*gpgsign[[:space:]]*=/ {
    print "  gpgsign = " (gpg ? "true" : "false")
    next
  }
  /commit = commit -s -S/ {
    print gpg ? $0 : "  commit = commit -s"
    next
  }
  /^[[:space:]]*t[[:space:]]*=[[:space:]]*tag -s/ {
    print gpg ? $0 : "  t      = tag"
    next
  }
  /^[[:space:]]*name[[:space:]]*=/ {
    print
    if (gpg) print "  signingKey = " key
    next
  }
  { print }
' "$template" > "$dest"

# Machine-specific paths, found on this machine at render time so the shared
# shell/.gitconfig never carries them (/bin/gpg on Linux is
# /opt/homebrew/bin/gpg on a Mac). The rendered profile is gitignored and
# included through ~/.gitconfig.local.
gpg_bin=$(command -v gpg 2>/dev/null || true)
gh_bin=$(command -v gh 2>/dev/null || true)
{
  echo
  echo "# --- machine-specific, rendered by $(basename "$0") ---"
  if [[ -n "$key" && -n "$gpg_bin" ]]; then
    printf '[gpg]\n  program = %s\n' "$gpg_bin"
  fi
  if [[ -n "$gh_bin" ]]; then
    for host in https://github.com https://gist.github.com; do
      printf '[credential "%s"]\n  helper =\n  helper = !%s auth git-credential\n' "$host" "$gh_bin"
    done
  fi
} >> "$dest"

if [[ -n "$key" ]]; then
  echo "wrote $dest (gpg on, $email $key)"
else
  echo "wrote $dest (gpg off, no key for $email)"
fi
