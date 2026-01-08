#!/bin/bash

packages=(
        "tcpdump"
        "vim"
        "htop"
        "tmux"
        "net-tools"
        "curl"
        "openssh-server"
        "openssh-client"
        "git"
        "python3"
        "sudo"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

if [[ $UID -ne 0 ]]
then
        echo -e "${RED}[!] Ce script doit être exécuté en tant que root [!]${NOCOLOR}"
        exit 2
fi

apt update
apt full-upgrade -y

for package in "${packages[@]}"
do
        apt install $package -y
done

echo "
alias ll='ls -lhF --color=auto'
alias la='ls -AlFh --color=auto'
alias ls='ls -Fh --color=auto'
alias svim='sudo vim'
" >> ~/.bashrc

source .bashrc

echo -e "${GREEN}[!] Post-installation terminée avec succès [!]${NOCOLOR}"