#!/usr/bin/env sh

if [ "${MYCELIO_LIBRARY_IMPORTED:-}" == "1" ]; then
    echo "Re-importing Mycelio shell library: '$MYCELIO_ROOT'"
else
    echo "Imported Mycelio shell library: '$MYCELIO_ROOT'"
fi

MYCELIO_LIBRARY_IMPORTED="1"
export MYCELIO_LIBRARY_IMPORTED

is_synology() {
    if uname -a | grep -q "synology"; then
        return 0
    fi

    return 1
}

_home="$(cd "$MYCELIO_ROOT" &>/dev/null && cd ../ && pwd)"
_home=${_home:-/var/services/homes/jvaneenwyk}
_logs="$_home/.logs"
_script_log_path="$_logs/${MYCELIO_SCRIPT_NAME:-mycelio}.log"
mkdir -p "$_logs"

# We use 'whoami' as $USER is not set for scheduled tasks
echo "User: '$(whoami)'" | tee "$_script_log_path"
echo "Home: '$_home'" | tee "$_script_log_path"
echo "Logs available here: '$_script_log_path'" | tee "$_script_log_path"
