# Set the path for pip/yarn/golang.
export PATH=~/.local/bin:~/go/bin:~/goroot/bin:/usr/local/bin:/usr/local/sbin:~/.yarn/bin:$PATH

# Use most as pager (for things like man, git diff, etc).
export PAGER=most

# Use emacs as default editor.
export EDITOR=code

# Enable go mod.
export GO111MODULE=on

export ZPLUG_HOME=~/.zplug
export GO_PATH=~/go/bin
export GO_PKG_PATH=$GO_PATH/pkg
export ANDROID_CMD_TOOLS

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export TOOLS="/home/qnlbnsl/tools"
export ANDROID_HOME="$TOOLS/android/android-sdk"
export ANDROID_SDK_ROOT="$TOOLS/android/android-sdk"
export ANDROID_NDK_HOME="$ANDROID_SDK_ROOT/ndk"
export JAVA_BIN="$JAVA_HOME/bin"
export CMD_TOOLS="$ANDROID_HOME/cmdline-tools/bin"
export PLATFORM_TOOLS="$ANDROID_HOME/platform-tools"

export PATH=$JAVA_BIN:$CMD_TOOLS:$PLATFORM_TOOLS:$GO_PATH:$GO_PKG_PATH:$PATH

# Show the git profile in the prompt.
export PROMPT='%{$fg_bold[yellow]%}[%m]%{$reset_color%}%{$fg_bold[blue]%}($(getgit))%{$reset_color%}'${PROMPT}

fpath=(
  ~/.zsh_functions
  ~/.zsh_functions/.aws
  "${fpath[@]}"
)

alias sdkmanager="sdkmanager --sdk_root=$ANDROID_SDK_ROOT"

# Enable nvm when using vscode.
if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi
