#!/bin/sh

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
get_real_path() {
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

_include() {
    # shellcheck disable=SC3028,SC3054,SC2039
    # MYCELIO_BASH_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

    # /workspaces/dotfiles/source/shell/lib

    # shellcheck disable=SC1090
    . "${MYCELIO_ROOT:-}/source/shell/${1:-}"
}

myc_include_all() {
    _include "lib/logging.sh"
    _include "lib/profile.sh"
    _include "lib/utilities.sh"
    _include "lib/path.sh"

    if [ -n "${BASH_VERSION:-}" ]; then
        _include "lib/pgp.bash"
        _include "lib/macos.bash"
        _include "lib/linux.bash"
        _include "lib/errors.bash"
        _include "lib/environment.bash"
        _include "lib/commands.bash"
        _include "lib/profile.bash"

        _include "apps/fzf.sh"
        _include "apps/git.sh"
        _include "apps/go.sh"
        _include "apps/hugo.sh"
        _include "apps/micro.sh"
        _include "apps/oh-my-posh.sh"
        _include "apps/powershell.sh"
        _include "apps/python.sh"
        _include "apps/stow.sh"
    fi
}

main() {
    myc_include_all
    myc_initialize_environment
}
