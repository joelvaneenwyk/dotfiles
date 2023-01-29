#!/usr/bin/env sh
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
#

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

    initialize
}

initialize_profile
