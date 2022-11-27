#!/bin/bash

_generate_ssh() {
    if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
        ssh-keygen -t ed25519 -C "joel.vaneenwyk@gmail.com"
        echo "Generated '~/.ssh/id_ed25519' SSH key."
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
    fi

    if [ -x "$(command -v clip)" ]; then
        clip <~/.ssh/id_ed25519.pub
    elif [ -x "$(command -v xclip)" ]; then
        xclip -sel clip <~/.ssh/id_ed25519.pub
    elif grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        "/mnt/c/Windows/System32/clip.exe" <"$HOME/.ssh/id_ed25519.pub"
    else
        echo "ERROR: Failed to find tool to copy public key to clipboard."
        return 99
    fi

    echo "Copied '~/.ssh/id_ed25519.pub' to clipboard."
    echo "1. Go to GitHub settings: https://github.com/settings/keys"
    echo "2. Press 'New SSH Key'"
    echo "3. Paste in the key from the clipboard and press 'Save'"
    echo "4. Once complete, press any key to continue to clone secrets repository..."
    read -r -n 1
}

_clone_secrets() {
    root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

    if [ ! -d "$root/secrets" ]; then
        git clone "git@github.com:joelvaneenwyk/secrets.git" "$root/secrets"
    fi

    git -C "$root" remote set-url origin "git@github.com:joelvaneenwyk/dotfiles.git"
    echo "Set remote origin to 'git@github.com:joelvaneenwyk/dotfiles.git'"
}

_generate_ssh
_clone_secrets
