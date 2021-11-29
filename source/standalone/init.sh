#!/bin/sh

use_sudo() {
    if [ -x "$(command -v sudo)" ] && [ ! -x "$(command -v cygpath)" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

if [ ! -x "$(command -v git)" ]; then
    if [ -x "$(command -v apt-get)" ]; then
        use_sudo apt-get update
        use_sudo apt-get install -y --no-install-recommends sudo git bash
    fi
else
    echo "✔ Skipped 'git' install as it already exists."
fi

if [ ! -f "${HOME:-}/dotfiles/setup.sh" ]; then
    git -C "${HOME:-}" clone -c core.symlinks=true --recursive "https://github.com/joelvaneenwyk/dotfiles.git"
else
    echo "✔ Skipped 'dotfiles' clone as it already exists: '$HOME/dotfiles'"
fi

git config --global --unset http.proxy
git config --global --unset https.proxy
bash "${HOME:-}/dotfiles/setup.sh"
