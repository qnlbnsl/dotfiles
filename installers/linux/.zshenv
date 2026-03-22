# Set the path for pip/yarn/golang.

# Use most as pager (for things like man, git diff, etc).
export PAGER=most
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
# Use vscode as default editor.
export EDITOR=cursor

# Enable go mod.
export GO111MODULE=on

# Build PATH dynamically — only add directories that exist.
typeset -U PATH path

[ -d ~/.goroot/bin ]         && export GO_PATH=~/.goroot/bin && path=($GO_PATH $path)
[ -d ~/.goroot/bin/pkg ]     && export GO_PKG_PATH=~/.goroot/bin/pkg && path=($GO_PKG_PATH $path)
[ -d "$HOME/.yarn/bin" ]     && path=("$HOME/.yarn/bin" $path)
[ -d "$HOME/.local/bin" ]    && path=("$HOME/.local/bin" $path)
[ -d "$HOME/.cargo/bin" ]    && export CARGO_HOME="$HOME/.cargo" && path=("$CARGO_HOME/bin" $path)
[ -d /usr/local/bin ]        && path=(/usr/local/bin /usr/local/sbin $path)

export PATH

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
