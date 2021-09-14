#!/usr/bin/env sh

is_synology() {
    if uname -a | grep -q "synology"; then
        return 0
    fi

    return 1
}

import() {
    if [ "${MYCELIO_LIBRARY_IMPORTED:-}" = "1" ]; then
        echo "Re-importing Mycelio shell library: '$MYCELIO_ROOT'"
    else
        echo "Imported Mycelio shell library: '$MYCELIO_ROOT'"
    fi

    if [ -n "${MYCELIO_ROOT:-}" ]; then
        _root_home="$(cd "${MYCELIO_ROOT:-}" >/dev/null 2>&1 && cd ../ && pwd)"
    fi

    _root_home=${_root_home:-/var/services/homes/$(whoami)}
    _home=${HOME:-$_root_home}
    _logs="$_home/.logs"
    mkdir -p "$_logs"

    MYCELIO_LOG_PATH="$_logs/${MYCELIO_SCRIPT_NAME:-mycelio}.log"
    export MYCELIO_LOG_PATH

    if [ ! "${MYCELIO_LIBRARY_IMPORTED:-}" = "1" ]; then
        # We use 'whoami' as 'USER' is not set for scheduled tasks
        echo "User: '$(whoami)'" | tee "$MYCELIO_LOG_PATH"
        echo "Home: '$_home'" | tee "$MYCELIO_LOG_PATH"
        echo "Logs available here: '$MYCELIO_LOG_PATH'" | tee "$MYCELIO_LOG_PATH"
    fi

    MYCELIO_LIBRARY_IMPORTED="1"
    export MYCELIO_LIBRARY_IMPORTED
}

import
