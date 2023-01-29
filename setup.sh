#!/bin/sh
#
# Usage: ./setup.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

try_sudo() {
    if [ -x "$(command -v sudo)" ] && [ ! -x "$(command -v cygpath)" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

setup() {
    # Standard safety protocol
    set -eu

    if [ -n "${BASH_VERSION:-}" ]; then
        echo "[mycelio] Bash v$BASH_VERSION"

        # shellcheck disable=SC3028,SC3054,SC2039
        _root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

        # shellcheck source=source/shell/main.sh
        . "$_root/source/shell/main.sh"

        if main "$@"; then
            _return_code=0
        else
            _return_code=$?
        fi
    else
        _root="$(cd -P -- "$(dirname -- "$0")" && pwd)"

        if [ ! -x "$(command -v bash)" ]; then
            if [ -x "$(command -v apk)" ]; then
                try_sudo apk update
                try_sudo apk add bash
            elif [ -x "$(command -v apt-get)" ]; then
                try_sudo apt-get update
                try_sudo apt-get install -y --no-install-recommends bash
            fi
        fi

        echo "[mycelio] Re-launching with Bash: '$_root/setup.sh'"

        # shellcheck source=setup.sh
        if bash "$_root/setup.sh" "$@"; then
            _return_code=0
        else
            _return_code=$?
            echo "[mycelio] Error code returned from bash setup: $_return_code"
        fi
    fi

    return ${_return_code:-99}
}

setup "$@"
