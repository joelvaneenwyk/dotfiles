#!/usr/bin/env bash

set -eu

root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

function is_shell_script() {
    [[ $1 == */configure ]] && return 2
    [[ $1 == */config.status ]] && return 2
    [[ $1 == */automake/* ]] && return 2
    [[ $1 == */base16*/* ]] && return 2
    [[ $1 == */fish/functions/* ]] && return 2
    [[ $1 == */git-fuzzy/* ]] && return 2
    [[ $1 == */test/bats/* ]] && return 2

    [[ $1 == */.zshrc ]] && return 3
    [[ $1 == */*.fish ]] && return 3

    [[ $1 == *.sh ]] && return 0
    [[ $1 == */bash-completion/* ]] && return 0

    # if [ -x "$(command -v file 2>&1)"]; then
    #     [[ "$(file -b --mime-type "$1")" == "text/x-shellscript" ]] && return 0
    # fi

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
    if shellcheck -help 2>&1 | grep -q 'source-path'; then
        _use_source_path=1
    else
        _use_source_path=0
    fi

    while IFS= read -r -d $'' file; do
        if is_shell_script "$file"; then
            if [ "$_use_source_path" = "1" ]; then
                if shellcheck --external-sources --enable=all --source-path="$root" --source-path="$root/source/stow" -W0 "$file"; then
                    echo "✔ $file"
                fi
            else
                if shellcheck --external-sources "$file"; then
                    echo "✔ $file"
                fi
            fi
        fi
    done < <(find "$root" -type f \! -path "$root/.git/*" -print0)
}

run_shellcheck
