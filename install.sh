#!/bin/bash

# Copying dotfiles to appropriate destination
mkdir ~/.config
cp -r nvim ~/.config/nvim
cp tmux.conf ~/.tmux.conf
cp vimrc ~/.vimrc
cp zshrc ~/.zshrc
cp vimspector.json ~/.vimspector.json
cp fzf.bash ~/.fzf.bash
cp fzf.zsh ~/.fzf.zsh
cp p10k.zsh ~/.p10k.zsh
touch ~/.bashrc

# Adding zshrc and fzf to bashrc
 echo 'zsh' >> ~/.bashrc
 echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> ~/.bashrc

#Update docker and install dependencies
sudo apt-get update; sudo apt install software-properties-common; sudo apt-get install python3-apt --reinstall; sudo apt-get install zsh; sudo apt-get install tmux

#Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

#Installing NodeJS (> 12.1 required)
cd ~/; sudo apt-get update; sudo pip uninstall neovim; sudo pip3 install neovim; curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get -y install nodejs

#Install vim plugin manager
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#Install ctags
sudo apt-get update; sudo apt-get install ctags

#Install nvim plugins
~/nvim.appimage -c ':PlugInstall|:UpdateRemotePlugins|qa!' ~/.config/nvim/init.vim
