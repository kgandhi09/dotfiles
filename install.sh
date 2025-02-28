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

install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh-My-Zsh..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
    else
        echo "Oh-My-Zsh already installed. Skipping..."
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    echo "Installing Zsh plugins..."
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$ZSH_CUSTOM"

    # install powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    # install fzf tab
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

    # install autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

# Install Vim-Plug for Neovim
install_vim_plug() {
    if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
        echo "Installing vim-plug for Neovim..."
        curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    else
        echo "vim-plug already installed. Skipping..."
    fi
}

# Install TPM for tmux
install_tpm() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        echo "TPM already installed. Skipping..."
    fi
}

# Symlink configuration files
setup_symlinks() {
    echo "Setting up symlinks..."
    ln -sf "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
    ln -sf "$DOTFILES_DIR/bash_aliases" "$HOME/.bash_aliases"
    ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"
    ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    ln -sf "$DOTFILES_DIR/tmux" "$HOME/.tmux"
}

# Install Neovim plugins
install_nvim_plugins() {
    echo "Installing Neovim plugins..."
    vim +'PlugInstall --sync' +qa

}

# Install Tmux plugins
install_tmux_plugins() {
    echo "Installing Tmux plugins..."
    $HOME/.tmux/plugins/tpm/bin/install_plugins
}

# Change default shell to Zsh
set_default_shell() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to Zsh..."
        chsh -s $(which zsh)
    fi
}

install_dependencies
install_oh_my_zsh
install_zsh_plugins
install_vim_plug
install_tpm
setup_symlinks
install_nvim_plugins
install_tmux_plugins
set_default_shell

echo "Installation complete! Restart your shell to apply changes."
