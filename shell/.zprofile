# Initialize Homebrew if available (macOS ARM64).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

# Added by swiftly
. '/home/qnlbnsl/.local/share/swiftly/env.sh'
