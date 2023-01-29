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

include() {
    # shellcheck disable=SC3028,SC3054,SC2039
    MYCELIO_BASH_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

    # shellcheck disable=SC1090
    . "$MYCELIO_BASH_DIR/${1:-}"
}

include_all() {
    include "lib/commands.sh"
    include "lib/environment.sh"
    include "lib/errors.sh"
    include "lib/linux.sh"
    include "lib/logging.sh"
    include "lib/macos.sh"
    include "lib/path.sh"
    include "lib/pgp.sh"
    include "lib/profile.bash"
    include "lib/profile.sh"
    include "lib/utilities.sh"

    include "apps/fzf.sh"
    include "apps/git.sh"
    include "apps/go.sh"
    include "apps/hugo.sh"
    include "apps/micro.sh"
    include "apps/oh-my-posh.sh"
    include "apps/powershell.sh"
    include "apps/python.sh"
    include "apps/stow.sh"
}

main() {
    include_all
    initialize_environment
}
