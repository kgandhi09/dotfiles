#!/bin/bash

# Set dotfiles directory (assumes script is in the same directory)
DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)

# Remove symlinks
echo "Removing symlinks..."
rm -f "$HOME/.bashrc"
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.zshrc"
rm -f "$HOME/.p10k.zsh"
rm -f "$HOME/.tmux.conf"
rm -rf "$HOME/.config/nvim"
rm -rf "$HOME/.tmux"

# Remove Oh-My-Zsh
echo "Removing Oh-My-Zsh..."
rm -rf "$HOME/.oh-my-zsh"

# Remove Zsh plugins
echo "Removing Zsh plugins..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom/plugins"
rm -rf "$ZSH_CUSTOM/fzf-tab"
rm -rf "$ZSH_CUSTOM/zsh-navigation-tools"
rm -rf "$ZSH_CUSTOM/zsh-autosuggestions"
rm -rf "$ZSH_CUSTOM/zsh-syntax-highlighting"
rm -rf "$ZSH_CUSTOM/web-search"
rm -rf "$ZSH_CUSTOM/jsontools"
rm -rf "$ZSH_CUSTOM/zsh-ask"

# Remove Vim-Plug for Neovim
echo "Removing vim-plug..."
rm -f "$HOME/.local/share/nvim/site/autoload/plug.vim"

# Remove TPM for tmux
echo "Removing Tmux Plugin Manager (TPM)..."
rm -rf "$HOME/.tmux/plugins/tpm"

echo "Uninstallation complete!"

