#!/bin/bash

# Update Neovim plugins
update_nvim_plugins() {
    echo "Updating Neovim plugins..."
    nvim --headless +PlugUpdate +qall
    echo "Neovim plugins updated successfully!"
}

update_nvim_plugins

