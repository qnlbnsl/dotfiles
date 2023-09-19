[ -n "${ZPROF}" ] && zmodload zsh/zprof

export TMUX_TZ=$(date +%Z)
export COLORTERM=truecolor
# User config.

# Docker compose shortcuts in addition to the docker-compose oh-my-zsh plugin.
alias dcu='docker-compose up -d --build -t 1'
alias dcd='docker-compose down -v -t 1'
alias dcr='docker-compose restart -t 1'

# Docker run with current user settings mounted in.
alias udockerrun='docker run --rm --user $(id -u):$(id -g) -e HOME -v $HOME:$HOME -w $(pwd) -e GOPATH=$HOME/go:/go'

# Reset gpg
alias gpgReset="gpgconf --kill gpg-agent"

# Switch python versions
alias setPython3="sudo apt install python-is-python3"
alias setPython2="sudo apt install python-is-python2"

# Oh-my-zsh config.

# Disable completion security check as it is too slow. Don't manually add any completions before checking them.
ZSH_DISABLE_COMPFIX=true

# If the ssh agent socket is not set or expired, reload it.
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
  rl
fi

ZSH_THEME="powerlevel10k/powerlevel10k"
CASE_SENSITIVE="true"

# Load oh-my-zsh.
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh


# TODO: Add ssh-agent plugin when not in remote server.
# Allow agent-forwarding.
# zstyle :omz:plugins:ssh-agent agent-forwarding on

# Enable shared history so we can reference history between terms.
setopt share_history
# Save each command in history to make sure we don't loose it.
setopt inc_append_history



# Load files for  functions
fpath=( ~/.zsh_functions "${fpath[@]}" )

# Load all functions from zsh_functions.
# TODO: Convert the following into a looped function
autoload -Uz ec2connect
autoload -Uz getgit
autoload -Uz rl
autoload -Uz setgit
autoload -Uz timezsh
autoload -Uz unsetaws

# Load more autocompletions.
# Uncomment o enable bash ccompinit mode
# autoload -U +X bashcompinit && bashcompinit
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C
complete -o nospace -C ${HOME}/go/bin/terraform terraform
complete -o nospace -C ${HOME}/go/bin/vault vault




# Putty bindings for meta left/right
bindkey '\e\eOD' backward-word
bindkey '\e\eOC' forward-word

# Xterm bindings for meta left/right.
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Set M-l as lowercase word.
bindkey "^[l" down-case-word

# Load the private config if set.
[ -f ~/.zshrc_priv_config ] && source ~/.zshrc_priv_config





export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export NVM_LAZY_LOAD=true
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('yarn')
# export NVM_AUTO_USE=true

export NVM_DIR="$HOME/.nvm"
  # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

connectaws () {
  eval "$(assumerole -f env $1)"
}

alias update-os="sudo apt-get update && sudo apt-get upgrade -y"

# Tell git to use the current tty for gpg passphrase prompt (needs to be at the end so the tty is within tmux, not out).
export GPG_TTY=$(tty)
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# load plugins here. Ideally this should not produce console output.
eval "$(sheldon source)"
[ -n "${ZPROF}" ] && zprof