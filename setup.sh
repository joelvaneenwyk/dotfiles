#!/bin/sh
#
# Usage: ./setup.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
_get_real_path() {
    _pwd="$(pwd)"
    _path="$1"
    _offset=""
    _real_path=""

    while :; do
        _base="$(basename "$_path")"

        if ! cd "$(dirname "$_path")" >/dev/null 2>&1; then
            break
        fi

        _link=$(readlink "$_base") || true
        _path="$(pwd)"

        if [ -n "$_link" ]; then
            if [ -f "$_path" ]; then
                _real_path=$(_get_real_path "$_link")
                break
            elif [ -f "$_link" ] || [ -d "$_link" ]; then
                _path="$_link"
            else
                _path="$_path/$_link"
            fi
        else
            _offset="/$_base$_offset"
        fi

        if [ "$_path" = "/" ]; then
            _real_path="$_offset"
            break
        else
            _real_path="$_path$_offset"
        fi
    done

    cd "$_pwd" || true
    echo "$_real_path"

    return 0
}

_use_sudo() {
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

        # shellcheck source=source/setup/mycelio.sh
        . "$_root/source/setup/mycelio.sh"

        if initialize_environment "$@"; then
            _return_code=0
        else
            _return_code=$?
        fi
    else
        _root="$(cd -P -- "$(dirname -- "$0")" && pwd)"

        if [ ! -x "$(command -v bash)" ]; then
            if [ -x "$(command -v apk)" ]; then
                _use_sudo apk update
                _use_sudo apk add bash
            elif [ -x "$(command -v apt-get)" ]; then
                _use_sudo apt-get update
                _use_sudo apt-get install -y --no-install-recommends bash
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
