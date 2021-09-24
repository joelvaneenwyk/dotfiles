#!/usr/bin/env bash

set -eu

root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

function is_shell_script() {
    [[ $1 == */configure ]] && return 2
    [[ $1 == */config.status ]] && return 2
    [[ $1 == */automake/* ]] && return 2
    [[ $1 == */base16*/* ]] && return 2
    [[ $1 == */git-fuzzy/* ]] && return 2
    [[ $1 == */test/bats/* ]] && return 2

    [[ $1 == */.zshrc ]] && return 3

    [[ $1 == *.sh ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0
    [[ $(file -b --mime-type "$1") == text/x-shellscript ]] && return 0

    return 1
}

function run_shellcheck() {
    if [ ! -x "$(command -v shellcheck)" ]; then
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get install shellcheck
        fi
    fi

    while IFS= read -r -d $'' file; do
        if is_shell_script "$file"; then
            shellcheck --external-sources --source-path="$root" --source-path="$root/source/stow" -W0 "$file" || continue
        fi
    done < <(find "$root" -type f \! -path "$root/.git/*" -print0)
}
