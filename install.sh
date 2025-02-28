#!/bin/bash

# Set dotfiles directory (assumes script is in the same directory)
DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)

# Install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update && sudo apt install -y tmux zsh curl git

    # Install Node.js 18
    echo "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs

    # Check Neovim version and install if necessary
    if ! command -v nvim &>/dev/null || [[ $(nvim --version | head -n1 | awk '{print $2}') < "0.10" ]]; then
        echo "Installing Neovim (version >= 0.10)..."
        sudo apt install -y neovim
    else
        echo "Neovim is already installed and meets the version requirement. Skipping..."
    fi
}

install_dependencies
