_log_debug() {
    if [ "${MYCELIO_DEBUG:-}" = "1" ]; then
        echo "$@"
    fi
}

_log_info() {
    echo "$@"
}

_log_warning() {
    echo "WARNING: $@"
}

function log_error() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::error::$*"
    fi

    echo "❌ $*"
}

function _filter() {
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
