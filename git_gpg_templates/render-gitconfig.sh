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

if [[ -n "$key" ]]; then
  echo "wrote $dest (gpg on, $email $key)"
else
  echo "wrote $dest (gpg off, no key for $email)"
fi
