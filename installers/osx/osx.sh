#! bin/bash
echo "Installing Xcode Command Line Tools"
xcode-select --install
echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
