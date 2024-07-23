# Set the path for pip/yarn/golang.

# Use most as pager (for things like man, git diff, etc).
export PAGER=most
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH 
# Use vscode as default editor.
export EDITOR=code

# Enable go mod.
export GO111MODULE=on

export ZPLUG_HOME=~/.zplug
export GO_PATH=~/.goroot/bin
export GO_PKG_PATH=$GO_PATH/pkg
export YARN_PATH=$HOME/.yarn/bin

export PATH=$GO_PATH:$GO_PKG_PATH:$HOME/.local/bin:$YARN_PATH:/usr/local/bin:/usr/local/sbin:$PATH

fpath=(
  ~/.zsh_functions
  "${fpath[@]}"
)

# Meta key is ALT
# Putty bindings for meta left/right
bindkey '\e\eOD' backward-word
bindkey '\e\eOC' forward-word

# Xterm bindings for meta left/right.
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Set M-l as lowercase word.
bindkey "^[l" down-case-word
. "$HOME/.cargo/env"
