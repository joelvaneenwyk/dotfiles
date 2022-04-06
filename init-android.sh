#!/bin/sh

termux-setup-storage

pkg install exa fish fzf git hub neovim stow

mkdir -p ~/.config/fish
mkdir -p ~/.ssh

stow android
stow bash
stow fish
stow vim

