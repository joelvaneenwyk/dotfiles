function __print_stack() {
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

function __safe_exit() {
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

function __trap_error() {
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
        __print_stack "$@" >&2
    fi

    # We always exit immediately on error
    __safe_exit ${_retval:-1}
}

function _remove_error_handling() {
    trap - ERR || true
    trap - DEBUG || true

    # oh-my-posh adds an exit handler (see https://git.io/JEPIq) which we do not want firing so remove that
    trap - EXIT || true

    return 0
}
