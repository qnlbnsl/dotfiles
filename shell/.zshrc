# Enable profiling if needed (uncomment to debug startup time)
# ZPROF=1
[ -n "${ZPROF}" ] && zmodload zsh/zprof

# Enable Powerlevel10k instant prompt (must be near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TMUX_TZ=$(date +%Z)
export COLORTERM=truecolor
export GPG_PROGRAM=$(which gpg)
export GPG_TTY=$(tty)
# User config.

source $HOME/.aliases

# Oh-my-zsh config.

# Disable completion security check as it is too slow. Don't manually add any completions before checking them.
ZSH_DISABLE_COMPFIX=true

# Enable shared history so we can reference history between terms.
setopt share_history
# Save each command in history to make sure we don't loose it.
setopt inc_append_history

ZSH_THEME="powerlevel10k/powerlevel10k"
CASE_SENSITIVE="true"

# Detect SSH session and set SSH agent-forwarding accordingly
if [[ -n "$SSH_CLIENT" || -n "$SSH_CONNECTION" ]]; then
  zstyle ':omz:plugins:ssh-agent' agent-forwarding on
fi

# Define oh-my-zsh plugins (loaded by oh-my-zsh.sh)
# Note: zsh-autosuggestions, zsh-syntax-highlighting, etc. are loaded via sheldon
plugins=(
  git
  yarn
  vscode
  golang
  terraform
  tmux
  docker
  docker-compose
  ssh-agent
)

# Load oh-my-zsh.
export ZSH=${HOME}/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Load files for functions
fpath=( ${HOME}/.zsh_functions "${fpath[@]}" )

source $HOME/.autoload

# Load the private config if set.
[ -f ${HOME}/.zshrc_priv_config ] && source ${HOME}/.zshrc_priv_config

connectaws () {
  eval "$(assumerole -f env $1)"
}

# If the ssh agent socket is not set or expired, reload it.
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
  rl
fi

# To customize prompt, run `p10k configure` or edit ${HOME}/.p10k.zsh.
[[ ! -f ${HOME}/.p10k.zsh ]] || source ${HOME}/.p10k.zsh
# load plugins here. Ideally this should not produce console output.
eval "$(sheldon source)"

# Lazy load AWS plugin
_load_aws() {
  # Unalias to prevent recursion
  unalias aws >/dev/null 2>&1

  # Source the actual oh-my-zsh aws plugin file
  local aws_plugin_file="${ZSH:-$HOME/.oh-my-zsh}/plugins/aws/aws.plugin.zsh"
  if [[ -f "$aws_plugin_file" ]]; then
    source "$aws_plugin_file"
  else
    echo "Error: AWS plugin file not found at $aws_plugin_file" >&2
  fi

  # Execute the original command
  aws "$@"
}
alias aws='_load_aws'

# Tell git to use the current tty for gpg passphrase prompt (needs to be at the end so the tty is within tmux, not out).
export GPG_TTY=$(tty)

_load_gcloud() {
  # Unalias the command to avoid recursive calls
  unalias gcloud >/dev/null 2>&1
  unalias gsutil >/dev/null 2>&1
  unalias bq >/dev/null 2>&1
  unalias docker-credential-gcr >/dev/null 2>&1
  unalias git-credential-gcloud.sh >/dev/null 2>&1

  # The next line updates PATH for the Google Cloud SDK.
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

  # The next line enables shell command completion for gcloud.
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

  # Execute the actual command
  "$@"
}

# Alias gcloud and related commands to the loader function
alias gcloud='_load_gcloud gcloud'
alias gsutil='_load_gcloud gsutil'
alias bq='_load_gcloud bq'
alias docker-credential-gcr='_load_gcloud docker-credential-gcr'
alias git-credential-gcloud.sh='_load_gcloud git-credential-gcloud.sh'


# Lazy load nvm
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unalias nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  "$@"
}
alias nvm='_load_nvm nvm'
alias node='_load_nvm node'
alias npm='_load_nvm npm'
alias npx='_load_nvm npx'

# Stop profiling
[ -n "${ZPROF}" ] && zprof