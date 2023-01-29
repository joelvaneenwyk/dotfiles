#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

initialize_profile() {
    if [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC3028,SC3054,SC2039
        _root="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

    else
        _root="$(cd -P -- "$(dirname -- "$0")" && pwd)"
    fi

    # shellcheck source=source/shell/main.sh
    . "$_root/source/shell/main.sh"

    include_all

    _initialize_bash_profile
}

initialize_profile
