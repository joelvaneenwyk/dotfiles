#!/bin/sh

termux-setup-storage

pkg install exa fish fzf git hub neovim stow

stow android
stow bash
stow fish
stow vim

