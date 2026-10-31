#!/usr/bin/env bash
# Interactive GitHub bootstrap for a fresh machine (dialog UI):
#   gh login -> pin GitHub's SSH host keys -> SSH key (create + upload) ->
#   GPG keys (create + upload) -> render git profiles -> verify SSH auth.
# Every step skips what is already done, so re-running is safe.
#
# Usage: github-setup.sh          run the setup (no-op when GitHub already works)
#        github-setup.sh --check  exit 0 if gh is logged in and SSH to GitHub
#                                 authenticates, 1 otherwise; never prompts
# Exit codes: 0 ready, 1 failed, 2 skipped by the user.
set -uo pipefail

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
SCOPES=admin:public_key,write:gpg_key
SSH_KEY=$HOME/.ssh/id_ed25519
GPG_EMAILS=(qnlbnsl@gmail.com kunal@immertec.com)
BACKTITLE="dotfiles: GitHub setup"

# The stamp target in common.mk that generates an email's key from git_gpg_templates/.
gpg_stamp() {
  case $1 in
    qnlbnsl@gmail.com)  echo "$HOME/.gpg_qnlbnsl_done" ;;
    kunal@immertec.com) echo "$HOME/.gpg_immertec_done" ;;
  esac
}

gh_ok()  { gh auth status -h github.com >/dev/null 2>&1; }
# GitHub's `ssh -T` exits 1 even on success, so match the greeting instead (and
# capture first: under pipefail, `ssh | grep` would report ssh's 1).
ssh_ok() {
  local out
  out=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -T git@github.com 2>&1 </dev/null)
  [[ $out == *"successfully authenticated"* ]]
}

if [[ ${1:-} == --check ]]; then
  gh_ok && ssh_ok
  exit
fi

if gh_ok && ssh_ok; then
  echo "GitHub already set up (gh logged in, SSH authenticates)."
  exit 0
fi

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "GitHub setup needs a terminal; run 'make github-setup' interactively." >&2
  exit 1
fi
for cmd in dialog gh gpg ssh ssh-keygen; do
  command -v "$cmd" >/dev/null || { echo "github-setup: '$cmd' not found" >&2; exit 1; }
done

# dialog prints its answer on stderr; swap so it can be captured.
d() { dialog --backtitle "$BACKTITLE" "$@" 3>&1 1>&2 2>&3; }
step() { clear; printf '\n==> %s\n\n' "$*"; }
fail() { d --title "GitHub setup failed" --msgbox "$*" 10 70; clear; echo "github-setup: $*" >&2; exit 1; }

d --title "GitHub setup" --yesno \
"GitHub isn't set up on this machine yet. This will:

  1. log in with the GitHub CLI (browser)
  2. create an SSH key if needed and upload it
  3. create GPG signing keys if needed and upload them
  4. render your git profiles and verify SSH works

founder-os is cloned afterwards. Set it up now?" 16 70 || { clear; exit 2; }

# ── 1. gh login (with the scopes needed to upload keys) ─────────────
if ! gh_ok; then
  step "Logging in to GitHub"
  gh auth login -h github.com -p ssh --skip-ssh-key -w -s "$SCOPES" || fail "gh auth login failed."
else
  have=$(gh api -i user 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="x-oauth-scopes"{print $2}')
  for s in ${SCOPES//,/ }; do
    if [[ ", $have," != *", $s,"* ]]; then
      step "Adding key-upload permissions to your GitHub login"
      gh auth refresh -h github.com -s "$SCOPES" || fail "gh auth refresh failed."
      break
    fi
  done
fi
gh config set -h github.com git_protocol ssh

# ── 2. Pin GitHub's SSH host keys (from the API, over HTTPS) ────────
# ~/.ssh/config may route github.com elsewhere (ssh.github.com:443), so ask ssh
# where it connects and which known_hosts file it uses.
read -r host port kh < <(ssh -G github.com | awk '
  $1=="hostname"{h=$2} $1=="port"{p=$2} $1=="userknownhostsfile"{k=$2}
  END{print h, p, k}')
kh=${kh/#\~/$HOME}
entry=$([[ $port == 22 ]] && echo "$host" || echo "[$host]:$port")
if ! ssh-keygen -F "$entry" -f "$kh" >/dev/null 2>&1; then
  keys=$(gh api meta --jq '.ssh_keys[]') || fail "Could not fetch GitHub's SSH host keys."
  mkdir -p "$(dirname "$kh")"
  while read -r k; do echo "$entry $k"; done <<<"$keys" >>"$kh"
fi

# ── 3. SSH key ───────────────────────────────────────────────────────
if [[ ! -f $SSH_KEY.pub ]]; then
  step "Creating SSH key $SSH_KEY (enter a passphrase, or leave empty)"
  mkdir -p "$(dirname "$SSH_KEY")" && chmod 700 "$(dirname "$SSH_KEY")"
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$SSH_KEY" || fail "ssh-keygen failed."
fi
pub=$(awk '{print $2}' "$SSH_KEY.pub")
if ! gh api user/keys --paginate --jq '.[].key' | grep -qF "$pub"; then
  step "Uploading SSH key to GitHub"
  gh ssh-key add "$SSH_KEY.pub" -t "$(hostname)" || fail "Uploading the SSH key failed."
fi

# ── 4. GPG keys ──────────────────────────────────────────────────────
items=()
for email in "${GPG_EMAILS[@]}"; do items+=("$email" "" on); done
chosen=$(d --title "GPG signing keys" --separate-output --checklist \
  "Create (if missing) and upload GPG keys for:" 12 60 4 "${items[@]}") || chosen=""
uploaded=$(gh api user/gpg_keys --paginate --jq '.[].key_id' 2>/dev/null)
for email in $chosen; do
  if ! gpg --list-secret-keys "$email" >/dev/null 2>&1; then
    step "Creating GPG key for $email"
    stamp=$(gpg_stamp "$email")
    rm -f "$stamp"
    make -C "$BASE_DIR" --no-print-directory "$stamp" || fail "Creating the GPG key for $email failed."
  fi
  keyid=$(gpg --list-secret-keys --with-colons "$email" | awk -F: '/^sec:/{print $5; exit}')
  if ! grep -qix "$keyid" <<<"$uploaded"; then
    step "Uploading GPG key $keyid ($email)"
    asc=$(mktemp)
    gpg --armor --export "$email" >"$asc"
    gh gpg-key add "$asc" -t "$(hostname) $email" || { rm -f "$asc"; fail "Uploading the GPG key for $email failed."; }
    rm -f "$asc"
  fi
done

# ── 5. Git profiles (signing on for keys that now exist) ────────────
step "Rendering git profiles"
make -C "$BASE_DIR" --no-print-directory gitsetup || fail "make gitsetup failed."

# ── 6. Verify ────────────────────────────────────────────────────────
step "Verifying SSH to GitHub"
ssh_ok || fail "SSH to GitHub still fails. Try: ssh -vT git@github.com"
user=$(gh api user --jq .login)
d --title "GitHub setup" --msgbox "Done. Logged in as $user and SSH to GitHub works." 7 60
clear
echo "GitHub setup done ($user)."
