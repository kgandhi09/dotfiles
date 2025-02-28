#!/bin/bash

# Set dotfiles directory (assumes script is in the same directory)
DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)

# Install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update && sudo apt install -y neovim tmux zsh curl git
}
