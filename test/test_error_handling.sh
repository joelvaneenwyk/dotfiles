#!/usr/bin/env bash
#
# Usage: ./setup.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
export MYCELIO_ROOT

source "$MYCELIO_ROOT/source/shell/mycelio.sh"

function _cause_error() {
    echo "derp"

    _error2=22

    if ! invalidcommand; then
        _error2=$?
    fi

    echo "return code: $_error2"

    return $_error2
}

_remove_error_handling
_setup_environment

#set +o errexit || true
#set +o xtrace || true
#set +o functrace || true
#set +o pipefail || true
#set +e

if ! _run "[test.error]" _cause_error; then
    echo ✔ You should see this message.
else
    echo ⚠ You should NOT see this message.
fi

echo Done.
_remove_error_handling
