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

#
# Run command and redirect stdout and stderr to logger at either info level or
# error level depending. Return error code of the command.
#
# Original implementation: https://unix.stackexchange.com/a/70675
#
# Resources:
#
#   - https://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself
#   - https://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another
#
function _custom_run() {
    _prefix="${1:-}"
    shift

    export MYCELIO_DISABLE_TRAP=1
    ( 
        ( 
            ( 
                ( 
                    ( 
                        (
                            echo "##[cmd] $*"

                            #  stdout (#1) -> untouched
                            #  stderr (#2) -> #3 (we then close it using "3>&-")
                            if "$@" 2>&3 3>&-; then
                                _error=0
                                echo "success"
                            else
                                _error=$?
                                echo "failure"
                                __print_error "$_error" 2>&3
                            fi

                            echo "$_error" >&5
                            exit $_error
                        ) | _filter "$_prefix [stdout]"           # Output standard log (stdout)
                    ) 3>&1 1>&4 | _filter "$_prefix [stderr]" >&2 # Pull stderr from 3 and redirect stdout to #4 so that it's not run through error log
                ) >&4
            ) 5>&1
        ) | (
            read -r xs
            exit "${xs:-0}"
        )
    ) 4>&1

    _error_out=$?

    return "$_error_out"
}

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

if ! _custom_run "[test.error]" _cause_error; then
    echo ✔ You should see this message.
else
    echo ⚠ You should NOT see this message.
fi

echo Done.
_remove_error_handling
