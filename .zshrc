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

# Docker wrappers for common tools.
alias swagger='udockerrun quay.io/goswagger/swagger'
alias protoc='udockerrun creack/grpc:go1.13-protobuf3.9.0-grpc1.24.0-protocgengo1.3.2'
alias prototool='udockerrun --entrypoint prototool creack/grpc:go1.13-protobuf3.9.0-grpc1.24.0-protocgengo1.3.2'

# Protobuf Go generation.
alias gprotoc='protoc --go_out=plugins=grpc:.'

# Protobuf Go Validations generation.
alias gvprotoc='gprotoc --validate_out=lang=go:.'

# GRPC Gateway generation.
alias gwprotoc='protoc --grpc-gateway_out="logtostderr=true:."'

# Swagger generation.
alias sprotoc='protoc --swagger_out="logtostderr=true:."'

# Recursive grep go file.
alias fggrep="fgrep -R --exclude-dir=vendor --exclude-dir=.cache --color --include='*.go'"

# Reset gpg
alias gpgReset="gpgconf --kill gpg-agent"

# Switch python versions
alias setPython3="sudo apt install python-is-python3"
alias setPython2="sudo apt install python-is-python2"

# Oh-my-zsh config.

# Disable completion security check as it is too slow. Don't manually add any completions before checking them.
ZSH_DISABLE_COMPFIX=true

# Tell git to use the current tty for gpg passphrase prompt (needs to be at the end so the tty is within tmux, not out).
export GPG_TTY=$(tty)

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


ZSH_THEME="powerlevel10k/powerlevel10k"
CASE_SENSITIVE="true"

# Load oh-my-zsh.
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

source $ZPLUG_HOME/init.zsh
# Zplug Plugins
zplug "qoomon/zsh-lazyload"
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/vscode", from:oh-my-zsh
zplug "plugins/golang", from:oh-my-zsh
zplug "plugins/aws", from:oh-my-zsh
zplug "plugins/terraform", from:oh-my-zsh
zplug "plugins/tmux", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
zplug "plugins/zsh-autosuggestions", from:oh-my-zsh
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting", from:github
zplug "zsh-users/zsh-history-substring-search", from:github, defer:2
zplug "djui/alias-tips", from:github

zplug load




# Set tmux autostart unless we are using vscode or emacs tramp.
# Create $HOME/.notmux file to skip tmux. "touch ~/.notmux"
if [ -n "$VSCODE_IPC_HOOK_CLI" ] || [ "$TERM" = "dumb" ] || [ -z "$TERM" ] || [ -f "$HOME/.notmux" ]; then
  ZSH_TMUX_AUTOSTART=false
else
  ZSH_TMUX_AUTOSTART=true
fi

# TODO: Add ssh-agent plugin when not in remote server.
# Allow agent-forwarding.
# zstyle :omz:plugins:ssh-agent agent-forwarding on



# Enable shared history so we can reference history between terms.
setopt share_history
# Save each command in history to make sure we don't loose it.
setopt inc_append_history



# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C ${HOME}/go/bin/terraform terraform
complete -o nospace -C ${HOME}/go/bin/vault vault


# If the ssh agent socket is not set or expired, reload it.
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
  rl
fi

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

[ -n "${ZPROF}" ] && zprof

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

gnb () {
  gcop red && git checkout -b $1 && git push -u origin $1
}

git-push () {
  git commit -S -m $1 && git push
}

gcop () {
    git checkout $1 && git pull
  }

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Lazy load for NVM plugin. This comes after NVM Export to make sure we have NVM on PATH
alias nvm="load_nvm && nvm"
load_nvm () {
    echo "loading nvm"
    unalias nvm
    echo "loading nvm plugin"
    zplug "lukechilds/zsh-nvm"
    zplug load
    echo "nvm loaded"
}

connectaws () {
  eval "$(assumerole -f env $1)"
}

alias reload="source ~/.zshrc"
