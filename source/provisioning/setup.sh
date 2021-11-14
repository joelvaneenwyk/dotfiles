#!/bin/sh

if [ ! -x "$(command -v git)" ]; then
    sudo apt-get update
    sudo apt install git
fi

_dotfiles="$HOME/dotfiles"
_provision="$HOME/dotfiles/source/provisioning/setup.sh"

if [ ! -d "$_dotfiles" ]; then
    git clone "https://github.com/joelvaneenwyk/dotfiles" "$_dotfiles"
fi

if [ ! -f "$_provision" ]; then
    git -C "$_dotfiles" pull
fi

if [ -f "$_provision" ]; then
    cd ~/dotfiles/source/provisioning/ubuntu/18.04/
fi
