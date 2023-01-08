#!/bin/bash

#List all containers and select which one to flash
export containers=$(sudo docker ps | awk '{if(NR>1) print $NF}')
export host=$(hostname)

echo "Select which container to flash .. "
export count_containers=1
for container in $containers
do
    echo "${count_containers}.) $container"
    count_containers=count_containers+1
done

export idx=-1
read -p '>> ' idx

#Get the name and container Id of the docker container to be flashed
export containers_list=($containers)
export container_name=${containers_list[${idx}-1]}
export container_id=`sudo docker ps -aqf "name=${container_name}"`

echo "Flashing ${container_name} ${container_id}..."
#Update docker and install dependencies
docker exec -it ${container_name} bash -c 'sudo apt-get update; sudo apt install software-properties-common; sudo apt-get install python3-apt --reinstall; sudo apt-get install zsh; sudo apt-get install tmux'

#Installing NodeJS (> 12.1 required)
docker exec -it ${container_name} bash -c 'cd ~/; sudo apt-get update; sudo pip uninstall neovim; sudo pip3 install neovim; curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -'
docker exec -it ${container_name} bash -c 'sudo apt-get -y install nodejs'

#Install vim plugin manager
docker exec -it ${container_name} sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

#Install ctags
docker exec -it ${container_name} bash -c 'sudo apt-get update; sudo apt-get install ctags'
