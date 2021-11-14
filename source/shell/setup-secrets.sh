#!/bin/bash

_generate_ssh() {
    if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
        ssh-keygen -t ed25519 -C "joel.vaneenwyk@gmail.com"
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519

        if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
            cat "$HOME/.ssh/id_ed25519.pub" | "/mnt/c/Windows/System32/clip.exe"
        else
            xclip -sel clip <~/.ssh/id_ed25519.pub
        fi
    fi

    echo "1. Go to GitHub settings: https://github.com/settings/keys"
    echo "2. Press 'New SSH Key'"
    echo "3. Paste in the key from the clipboard and press 'Save'"
    echo "4. Press any key to continue..."

    while [ true ]; do
        read -t 3 -n 1
        if [ $? = 0 ]; then
            break
        else
            echo "Waiting for the keypress..."
        fi
    done
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
