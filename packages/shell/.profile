#!/usr/bin/env sh
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
#

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
_get_real_path() {
    _pwd="$(pwd)"
    _path="${1:-}"
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
                _real_path=$(get_real_path "$_link")
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

_main_profile() {
    if [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC3028,SC3054,SC2039
        MYCELIO_ROOT="${BASH_SOURCE[0]}"
    else
        MYCELIO_ROOT="$0"
    fi

    if [ ! -e "${MYCELIO_ROOT:-}/setup.sh" ]; then
        export MYCELIO_ROOT="$HOME/dotfiles"

        if [ ! -e "$MYCELIO_ROOT/setup.sh" ]; then
            export MYCELIO_ROOT="$HOME/.dotfiles"
        fi

        if [ ! -e "$MYCELIO_ROOT/setup.sh" ]; then
            export MYCELIO_ROOT="/workspaces/dotfiles"
        fi
    fi

    # _dotfiles_root="$(_get_real_path "$_root")"
    # echo $_dotfiles_root

    if [ -e "$MYCELIO_ROOT/source/shell/main.sh" ]; then
        # shellcheck source=source/shell/main.sh
        . "$MYCELIO_ROOT/source/shell/main.sh"

        include_all

        initialize
    fi
}

_main_profile
