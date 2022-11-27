#!/usr/bin/env bash

set -eu

root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

function is_shell_script() {
    [[ $1 == */.git/* ]] && return 2
    [[ $1 == */configure ]] && return 2
    [[ $1 == */config.status ]] && return 2
    [[ $1 == */automake/* ]] && return 2
    [[ $1 == */base16*/* ]] && return 2
    [[ $1 == */fish/functions/* ]] && return 2
    [[ $1 == */git-fuzzy/* ]] && return 2
    [[ $1 == */secrets/* ]] && return 2
    [[ $1 == */test/test_helper/bats*/* ]] && return 2

    [[ $1 == */.zshrc ]] && return 3
    [[ $1 == */*.fish ]] && return 3

    [[ $1 == *.profile ]] && return 0
    [[ $1 == *.sh ]] && return 0
    [[ $1 == *.bash ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0
    [[ $(file -b --mime-type "$1") == text/x-shellscript ]] && return 0

    return 1
}

function install_shellcheck() {
    if [ ! -x "$(command -v shellcheck)" ]; then
        if [ -x "$(command -v brew)" ]; then
            brew install shellcheck
        elif [ -x "$(command -v apt-get)" ]; then
            sudo apt-get install shellcheck
        fi
    fi
}

function run_shellcheck() {
    _args=("${@}")
    _args+=(--external-sources --format=gcc --color=always)
    _args+=(--enable=all --exclude="SC2292,SC2250,SC2248,SC2248,SC2312,SC2310")

    if shellcheck -help 2>&1 | grep -q 'source-path'; then
        _args+=(--source-path="$root" --source-path="$root/source/stow")
    fi

    echo "##[cmd] shellcheck ${_args[*]} [FILES]"

    while IFS= read -r -d $'' file; do
        if is_shell_script "$file"; then
            if shellcheck "${_args[@]}" "$file"; then
                echo "✔ $file"
            else
                echo "❌ $file"
            fi
        else
            # Skipped the file
            :
        fi
    done < <(find "$root" -type f \! -path "$root/.git/*" -print0)
}

run_shellcheck "$@"
