#!/bin/bash

mkdir ~/.config
cp -r nvim ~/.config/nvim

#Update docker and install dependencies
sudo apt-get update; sudo apt install software-properties-common; sudo apt-get install python3-apt --reinstall; sudo apt-get install zsh; sudo apt-get install tmux

#Installing NodeJS (> 12.1 required)
cd ~/; sudo apt-get update; sudo pip uninstall neovim; sudo pip3 install neovim; curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get -y install nodejs

#Install vim plugin manager
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#Install ctags
sudo apt-get update; sudo apt-get install ctags
