#!/bin/bash

function _print_stack() {
    if [ -n "${BASH:-}" ]; then

        source_index=0
        function_index=1
        callstack_end=${#FUNCNAME[@]}

        local callstack=""
        while ((function_index < callstack_end)); do
            function=${FUNCNAME[$function_index]+"${FUNCNAME[$function_index]}"}
            callstack+=$(printf '\\n    >  %s:%d: %s()' "${BASH_SOURCE[$source_index]}" "${BASH_LINENO[$source_index]}" "${function:-}")
            ((++function_index))
            ((++source_index))
        done

        printf "%b\n" "$callstack" >&2
    fi

    return 0
}

function _safe_exit() {
    _value=$(expr "${1:-}" : '[^0-9]*\([0-9]*\)' 2>/dev/null || :)

    if [ -z "${_value:-}" ]; then
        # Not a supported return value so provide a default
        exit 199
    fi

    # We intentionally do not double quote this because we are expecting
    # this to be a number and exit does not accept strings.
    # shellcheck disable=SC2086
    exit $_value
}

function setup_error_handler() {
    # We only output command on Bash because by default "-x" will output to 'stderr' which
    # results in an error on CI as it's used to make sure we have clean output. On Bash we
    # can override to to go to a new file descriptor.
    if [ -z "${BASH:-}" ]; then
        echo "No error handling enabled. Only supported in bash shell."
    else
        shopt -s extdebug

        # aka. set -T
        set -o functrace

        # The return value of a pipeline is the status of
        # the last command to exit with a non-zero status,
        # or zero if no command exited with a non-zero status.
        set -o pipefail

        _mycelio_dbg_line=
        export _mycelio_dbg_line

        _mycelio_dbg_last_line=
        export _mycelio_dbg_last_line

        # 'ERR' is undefined in POSIX. We also use a somewhat strange looking expansion here
        # for 'BASH_LINENO' to ensure it works if BASH_LINENO is not set. There is a 'gist' of
        # at https://bit.ly/3cuHidf along with more details available at https://bit.ly/2AE2mAC.
        trap '_mycelio_trap_error "$LINENO" ${BASH_LINENO[@]+"${BASH_LINENO[@]}"}' ERR

        _enable_trace=0
        _bash_debug=0

        # Using debug output is performance intensive as the trap is executed for every single
        # call so only enable it if specifically requested.
        if [ "${MYCELIO_ARG_DEBUG:-0}" = "1" ] && [ -z "${BATS_TEST_NAME:-}" ]; then
            # Redirect only supported in Bash versions after 4.1
            if [ "$BASH_VERSION_MAJOR" -eq 4 ] && [ "$BASH_VERSION_MINOR" -ge 1 ]; then
                _enable_trace=1
            elif [ "$BASH_VERSION_MAJOR" -gt 4 ]; then
                _enable_trace=1
            fi

            if [ "$_enable_trace" = "1" ]; then
                trap '[[ "${FUNCNAME:-}" == "_mycelio_trap_error" ]] || {
                    _mycelio_dbg_last_line=${_mycelio_dbg_line:-};
                    _mycelio_dbg_line=${LINENO:-};
                }' DEBUG || true

                _bash_debug=1

                # Error tracing (sub shell errors) only work properly in version >=4.0 so
                # we enable here as well. Otherwise errors in subshells can result in ERR
                # trap being called e.g. _my_result="$(errorfunc test)"
                set -o errtrace

                # If set, command substitution inherits the value of the errexit option, instead of unsetting it in the
                # subshell environment. This option is enabled when POSIX mode is enabled.
                shopt -s inherit_errexit

                export MYCELIO_DEBUG_TRAP_ENABLED=1
            fi
        fi

        MYCELIO_DEBUG_TRACE_FILE=""

        # Output trace to file if that is supported
        if [ "$_bash_debug" = "1" ] && [ "$_enable_trace" = "1" ]; then
            MYCELIO_DEBUG_TRACE_FILE="$MYCELIO_HOME/.logs/init.xtrace.$(date +%s).log"
            mkdir -p "$MYCELIO_HOME/.logs"

            # Find a free file descriptor
            log_descriptor=${BASH_XTRACEFD:-19}

            while ((log_descriptor < 31)); do
                if eval "command >&$log_descriptor" >/dev/null 2>&1; then
                    eval "exec $log_descriptor>$MYCELIO_DEBUG_TRACE_FILE"
                    export BASH_XTRACEFD=$log_descriptor
                    set -o xtrace
                    break
                fi

                ((++log_descriptor))
            done
        fi

        export MYCELIO_DEBUG_TRACE_FILE
    fi
}

function _mycelio_trap_error() {
    _retval=$?

    if [ ! "${MYCELIO_DISABLE_TRAP:-}" == "1" ]; then
        _line=${_mycelio_dbg_last_line:-}

        if [ "${_line:-}" = "" ]; then
            _line="${1:-}"
        fi

        if [ "${_line:-}" = "" ]; then
            _line="[undefined]"
        fi

        # First argument is always the line number even if unused
        shift

        echo "--------------------------------------" >&2

        if [ "${MYCELIO_DEBUG_TRAP_ENABLED:-}" = "1" ]; then
            echo "Error on line #$_line:" >&2
        fi

        # This only exists in a few shells e.g. bash
        # shellcheck disable=SC2039,SC3044
        if _caller="$(caller 2>&1)"; then
            printf " - Caller: '%s'\n" "${_caller:-UNKNOWN}" >&2
        fi

        printf " - Code: '%s'\n" "${_retval:-}" >&2
        printf " - Callstack:" >&2
        _print_stack "$@" >&2
    fi

    # We always exit immediately on error
    _safe_exit ${_retval:-1}
}

function remove_error_handling() {
    trap - ERR || true
    trap - DEBUG || true

    # oh-my-posh adds an exit handler (see https://git.io/JEPIq) which we do not want firing so remove that
    trap - EXIT || true

    return 0
}
