#!/bin/sh

log_debug() {
    if [ "${MYCELIO_DEBUG:-}" = "1" ]; then
        echo "$@"
    fi
}

log_info() {
    echo "$@"
}

log_warning() {
    echo "WARNING: $*"
}

log_error() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::error::$*"
    fi

    echo "❌ $*"
}

_filter() {
    _prefix="$1"
    _ifs="$IFS"
    IFS=''

    while read -r line; do
        if [ -n "$line" ]; then
            # Could use the following to remove all surrounding whitespace but this
            # is performance heavy so just ignore for now.
            # line=$(echo $line | xargs)

            echo "$_prefix $line"
        fi
    done

    IFS="$_ifs"
}
