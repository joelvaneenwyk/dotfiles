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
        use_sudo apt-get install -y --no-install-recommandations git
    fi
fi
