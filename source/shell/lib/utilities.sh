function _command_exists() {
    if command -v "$@" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

#
# Some platforms (e.g. MacOS) do not come with 'timeout' command so
# this is a cross-platform implementation that optionally uses perl.
#
function _timeout() {
    _seconds="${1:-}"
    shift

    if [ ! "$_seconds" = "" ]; then
        if _command_exists "gtimeout"; then
            gtimeout "$_seconds" "$@"
        elif _command_exists "perl"; then
            perl -e "alarm $_seconds; exec @ARGV" "$@"
        else
            eval "$@"
        fi
    fi
}

#
# Get system permission status to help determine if we are able to
# do package installs.
#
#   - https://superuser.com/questions/553932/how-to-check-if-i-have-sudo-access
#
function _has_admin_rights() {
    # If 'sudo' does not exist at all then assume we can use it
    if ! _command_exists "sudo"; then
        return 0
    else
        _user="$(whoami)"

        # -n -> 'non-interactive'
        # -v -> 'validate'
        if _prompt="$(sudo -nv -u "$_user" 2>&1)"; then
            # Has sudo password set
            return 0
        fi

        if echo "${_prompt:-}" | grep -q '^sudo:'; then
            # Password needed for access.
            return 1
        fi

        # Initial attempt failed
        if _sudo_machine_output="$(uname -s 2>/dev/null)"; then
            case "${_sudo_machine_output:-}" in
            Darwin*)
                if dscl . -authonly "$_user" "" >/dev/null 2>&1; then
                    # Password is empty string.
                    return 0
                else
                    # Authority check failed
                    if _timeout 2 sudo id >/dev/null 2>&1; then
                        # If this passes then we do have a password set
                        return 0
                    fi
                fi
                ;;
            *) ;;
            esac
        fi
    fi

    # No status discovered, assuming password needed.
    return 1
}

function _allow_sudo() {
    # If the command does not exist we can't use it
    if [ ! -x "$(command -v sudo)" ]; then
        return 1
    fi

    # Avoid running sudo on Windows even if command exists
    if [ -n "${MSYSTEM_CARCH:-}" ] || [ "${MYCELIO_OS:-}" = "windows" ]; then
        return 2
    fi

    # If we are fine with interactive prompts, then it doesn't matter if we have permission
    # with sudo or not.
    if [ "${MYCELIO_INTERACTIVE:-}" = "1" ]; then
        return 0
    fi

    # If we get here we have everything we need but we want to make sure
    # we can run sudo without prompt since we are running in non-interactive
    # mode and do not want to stall CI builds.
    if _has_admin_rights; then
        return 0
    fi

    echo "⚠ Password required for sudo."

    # We must not have admin rights so we are not allowed to sudo
    return 5
}

function run_sudo() {
    if _allow_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

# Modified from '/usr/bin/wslvar' to support MSYS2 environments as well.
function _get_windows_root() {
    out_prefix="/mnt/c/"

    if [ -f "/etc/wsl.conf" ]; then
        _tmp=$(awk -F '=' '/root/ {print $2}' /etc/wsl.conf | awk '{$1=$1;print}' | sed 's/\/*$//g')
        if [ -f "$_tmp/c/Windows/explorer.exe" ]; then
            out_prefix="$_tmp/c/"
        fi
    elif [ -f "/c/Windows/explorer.exe" ]; then
        out_prefix="/c/"
    fi

    if [ -f "$out_prefix/Windows/explorer.exe" ]; then
        # Remove trailing slash
        echo "$out_prefix" | sed 's/\/*$//g'
    else
        echo ""
    fi
}

function _is_windows() {
    case "$(uname -s)" in
    CYGWIN*)
        return 0
        ;;
    MINGW*)
        return 0
        ;;
    MSYS*)
        return 0
        ;;
    esac

    return 1
}

_init_sudo() {
    if [ -z "${MYCO_SUDO:-}" ]; then
        _status=""

        if [ ! -x "$(command -v sudo)" ]; then
            _status="no_sudo"
        fi

        if [ -z "${_status:-}" ] && _sudo_machine_output="$(uname -s 2>/dev/null)"; then
            case "${_sudo_machine_output:-}" in
            CYGWIN* | MINGW*)
                _status="unsupported_platform"
                ;;
            Darwin*)
                if dscl . -authonly "$(whoami)" "" >/dev/null 2>&1; then
                    _status="has_sudo__pass_set"
                fi
                ;;
            *) ;;
            esac
        fi

        if [ -z "${_status:-}" ]; then
            # We first attempt to validate ('-v') the user which will refresh the timestamp and
            # essentially "login" if a password is not required.
            _timeout 1 sudo -v >/dev/null 2>&1

            if _sudo_id="$(_timeout 1 sudo -n id 2>&1)"; then
                _status="has_sudo__pass_set"
            else
                _status="has_sudo__needs_pass"
            fi
        fi

        if [ -z "${_status:-}" ]; then
            # -n -> 'non-interactive'
            # -v -> 'validate'
            if _prompt="$(sudo -nv 2>&1)"; then
                _status="has_sudo__pass_set"
            fi

            if echo "${_prompt:-}" | grep -q '^sudo: a password is required'; then
                _status="has_sudo__needs_pass"
            fi
        fi

        if [ "${_status:-}" = "has_sudo__pass_set" ]; then
            export MYCO_SUDO=1
        else
            if [ "${_status:-}" = "has_sudo__needs_pass" ]; then
                _log_warning "Not using 'sudo' as it requires a password. Pass '--sudo' to prompt for password."
            elif [ "${_status:-}" = "no_sudo" ]; then
                _log_debug "Command 'sudo' not found or installed."
            elif [ "${_status:-}" = "unsupported_platform" ]; then
                _log_warning "Command 'sudo' not supported on this platform."
            fi

            export MYCO_SUDO=0
        fi
    fi
}

# Runs the command passed in as an argument with sudo if we have sudo permissions or are
# allowed to run interactively. If sudo command does not exist, we just run the command.
#######################################
_sudo() {
    _init_sudo

    if [ ! -x "$(command -v sudo)" ]; then
        "$@"
    elif [ "${MYCO_SUDO:-}" = "1" ]; then
        sudo "$@"
    else
        _log_warning "Skipped command: '$*'"
    fi
}
