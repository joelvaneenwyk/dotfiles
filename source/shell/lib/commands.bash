function run_command_sudo() {
    _prefix="${1:-}"
    shift

    if allow_sudo; then
        run_command "$_prefix" sudo "$@"
    else
        run_command "$_prefix" "$@"
    fi
}

function task_group() {
    _name="${1:-}"
    shift

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::group::$_name"
    else
        echo "##[task] $_name"
    fi

    "$@"

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::endgroup::"
    fi
}

function run_task() {
    _name="${1:-}"
    _prefix="$(echo "${_name// /.}" | awk '{print tolower($0)}')"
    shift
    task_group "$_name" run_command "$_prefix" "$@"
}

function run_task_sudo() {
    _name="${1:-}"
    _prefix="$(echo "${_name// /.}" | awk '{print tolower($0)}')"
    shift
    if allow_sudo; then
        task_group "$_name" run_command "$_prefix" sudo "$@"
    else
        task_group "$_name" run_command "$_prefix" "$@"
    fi
}

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
function run_command() {
    _prefix="${1:-}"
    shift

    local command_display
    command_display="$*"
    command_display=${command_display//$'\n'/} # Remove all newlines
    command_display=${command_display%$'\n'}   # Remove trailing newline

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "[command]$command_display"
    else
        echo "##[cmd] $command_display"
    fi

    (
        export MYCELIO_DISABLE_TRAP=1
        ( 
            ( 
                (
                    unset MYCELIO_DISABLE_TRAP

                    #  stdout (#1) -> untouched
                    #  stderr (#2) -> #3
                    "$@" 2>&3 3>&-
                ) | _filter "[$_prefix.out]"           # Output standard log (stdout)
            ) 3>&1 1>&4 | _filter "[$_prefix.err]" >&2 # Redirects stdout to #4 so that it's not run through error log
        ) >&4
    ) 4>&1

    return $?
}
