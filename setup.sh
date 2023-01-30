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

try_find_root() {
    relative_file="source/shell/main.sh"

    if [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC3028,SC3054,SC2039
        root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    else
        root=$(dirname "$0")
    fi

    if [ ! -e "${root:-}/$relative_file" ]; then
        root="$HOME/dotfiles"
    fi

    if [ ! -e "${root:-}/$relative_file" ]; then
        root="$HOME/.dotfiles"
    fi

    if [ ! -e "${root:-}/$relative_file" ]; then
        root="/home/runner/work/dotfiles/"
    fi

    if [ ! -e "${root:-}/$relative_file" ]; then
        root=""
    fi

    echo "${root}"

    if [ -z "${root}" ]; then
        return 55
    fi

    return 0
}

setup() {
    # Standard safety protocol
    set -eu

    if [ -n "${BASH_VERSION:-}" ]; then
        echo "[mycelio] Bash v$BASH_VERSION"

        # shellcheck disable=SC3028,SC3054,SC2039
        _root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

        if root="$(try_find_root)"; then
            # shellcheck source=source/shell/main.sh
            . "$root/source/shell/main.sh"

            if main "$@"; then
                _return_code=0
            else
                _return_code=$?
            fi
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
