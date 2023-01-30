#!/usr/bin/env bash
#
# Usage: ./setup.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

function install_packages() {
    if uname -a | grep -q "synology"; then
        echo "Skipped installing dependencies. Not supported on Synology platform."
    elif [ -x "$(command -v pacman)" ]; then
        # Primary driver for these dependencies is 'stow' but they are generally useful as well
        echo "[mycelio] Installing minimal packages to build dependencies on Windows using MSYS2."

        # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
        rm -f /var/lib/pacman/db.lck

        run_command "pacman.update.database" pacman -Fy

        run_command "pacman.install" pacman -S --quiet --noconfirm --needed \
            msys2-keyring \
            curl wget unzip \
            git gawk perl \
            fish tmux \
            texinfo texinfo-tex \
            base-devel gcc gcc-libs binutils make autoconf automake1.16 automake-wrapper libtool \
            msys2-runtime-devel msys2-w32api-headers msys2-w32api-runtime

        if [ "${MSYSTEM:-}" = "MINGW64" ]; then
            run_command "pacman.install.mingw64" pacman -S --quiet --noconfirm --needed \
                mingw-w64-x86_64-make mingw-w64-x86_64-gcc mingw-w64-x86_64-binutils
        fi

        # Unsure why but for some reason a link for cc1 is not created which results in errors
        # during builds of some Perl dependencies.
        _cc1="/usr/lib/gcc/x86_64-pc-msys/10.2.0/cc1.exe"
        if [ -f "$_cc1" ] && [ ! -e "/usr/bin/cc1.exe" ]; then
            ln -s "$_cc1" "/usr/bin/cc1.exe"
        fi

        if [ -f "/etc/pacman.d/gnupg/" ]; then
            rm -rf "/etc/pacman.d/gnupg/"
        fi
    elif [ -x "$(command -v apk)" ]; then
        run_command_sudo "apk.update" apk update
        run_command_sudo "apk.add" apk add \
            sudo tzdata git wget curl unzip xclip \
            build-base gcc g++ make musl-dev openssl-dev zlib-dev \
            perl perl-dev perl-utils \
            bash tmux neofetch fish \
            python3 py3-pip \
            fontconfig openssl gnupg
    elif [ -x "$(command -v apt-get)" ]; then
        run_command_sudo "apt.update" \
            apt-get update

        # Needed to prevent interactive questions during 'tzdata' install, see https://stackoverflow.com/a/44333806
        run_command_sudo "timezone.set" \
            ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime >/dev/null 2>&1

        DEBIAN_FRONTEND="noninteractive" run_command_sudo "apt.install" \
            apt-get install -y --no-install-recommends \
            sudo gpgconf ca-certificates tzdata git wget curl unzip xclip libnotify-bin \
            software-properties-common apt-transport-https \
            build-essential gcc g++ make automake autoconf \
            libssl-dev openssl libz-dev perl cpanminus \
            tmux neofetch fish zsh bash \
            python3 python3-pip \
            shellcheck \
            fontconfig

        if [ -x "$(command -v dpkg-reconfigure)" ]; then
            run_command_sudo "timezone.reconfigure" dpkg-reconfigure --frontend noninteractive tzdata
        fi
    fi
}

#
# Minimal set of required environment variables that the rest of the script relies
# on heavily to operate including setting up error handling. It is therefore critical
# that this function is error free and handles all edge cases for all supported
# platforms.
#
function setup_environment() {
    MYCELIO_ROOT="$(cd "$(dirname "$(get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../../ && pwd)"
    export MYCELIO_ROOT

    # Get home path which is hopefully in 'HOME' but if not we use the parent
    # directory of this project as a backup.
    HOME=$(_remove_trailing_slash "${HOME:-"$(cd "$MYCELIO_ROOT" && cd .. && pwd)"}")
    export HOME

    export MYCELIO_HOME="$HOME"
    export MYCELIO_STOW_ROOT="$MYCELIO_ROOT/source/stow"
    export MYCELIO_DEBUG_TRAP_ENABLED=0
    export MYCELIO_TEMP="$MYCELIO_HOME/.tmp"

    # set -u
    set -o nounset

    # We do not set exit on error as our custom error trap handles this.
    # set -e
    # set -o errexit

    if [ -n "${BASH:-}" ]; then
        BASH_VERSION_MAJOR=$(echo "$BASH_VERSION" | cut -d. -f1)
        BASH_VERSION_MINOR=$(echo "$BASH_VERSION" | cut -d. -f2)
    else
        BASH_VERSION_MAJOR=0
        BASH_VERSION_MINOR=0
    fi

    export BASH_VERSION_MAJOR
    export BASH_VERSION_MINOR

    export MYCELIO_DEBUG_TRAP_ENABLED=0

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
        # trap '__trap_error "$LINENO" ${BASH_LINENO[@]+"${BASH_LINENO[@]}"}' ERR

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
                trap '[[ "${FUNCNAME:-}" == "__trap_error" ]] || {
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

    load_profile

    if [ -x "$(command -v apk)" ]; then
        _arch_name="$(apk --print-arch)"
    else
        _arch_name="$(uname -m)"
    fi

    MYCELIO_ARCH=""
    MYCELIO_ARM=""
    MYCELIO_386=""

    case "$_arch_name" in
    'x86_64')
        MYCELIO_ARCH='amd64'
        ;;
    'armhf')
        MYCELIO_ARCH='arm'
        MYCELIO_ARM='6'
        ;;
    'armv7')
        MYCELIO_ARCH='arm'
        MYCELIO_ARM='7'
        ;;
    'armv7l')
        # Raspberry PI
        MYCELIO_ARCH='arm'
        MYCELIO_ARM='7'
        ;;
    'aarch64')
        MYCELIO_ARCH='arm64'
        ;;
    'x86')
        MYCELIO_ARCH='386'
        MYCELIO_386='softfloat'
        ;;
    'ppc64le')
        MYCELIO_ARCH='ppc64le'
        ;;
    's390x')
        MYCELIO_ARCH='s390x'
        ;;
    *)
        echo >&2 "[mycelio] ERROR: Unsupported architecture '$_arch_name'"
        exit 1
        ;;
    esac

    export MYCELIO_ARCH MYCELIO_386 MYCELIO_ARM

    MYCELIO_OS="$(uname -s)"
    case "${MYCELIO_OS}" in
    Linux*)
        MYCELIO_OS='linux'
        ;;
    Darwin*)
        MYCELIO_OS='darwin'
        ;;
    CYGWIN* | MINGW* | MSYS*)
        MYCELIO_OS='windows'
        ;;
    esac
    export MYCELIO_OS

    if [ -n "${BASH_VERSION:-}" ]; then
        MYCELIO_SHELL="bash v$BASH_VERSION"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        MYCELIO_SHELL="zsh v$ZSH_VERSION"
    elif [ -n "${KSH_VERSION:-}" ]; then
        MYCELIO_SHELL="ksh v$KSH_VERSION"
    elif [ -n "${version:-}" ]; then
        MYCELIO_SHELL="sh v$version"
    else
        MYCELIO_SHELL="N/A"
    fi
    export MYCELIO_SHELL
}

function _parse_arguments() {
    # Assume we are fine with interactive prompts (e.g., request for password) if necessary
    export MYCELIO_INTERACTIVE=1

    export MYCELIO_ARG_CLEAN=0
    export MYCELIO_ARG_FORCE=0
    export MYCELIO_ARG_DEBUG=0

    local POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
        -c | --clean)
            export MYCELIO_ARG_CLEAN=1
            shift # past argument
            ;;
        -d | --debug)
            export MYCELIO_ARG_DEBUG=1
            shift # past argument
            ;;
        -f | --force)
            export MYCELIO_ARG_FORCE=1
            shift # past argument
            ;;
        -y | --yes)
            # Equivalent to the apt-get "assume yes" of '-y'
            export MYCELIO_INTERACTIVE=0
            shift # past argument
            ;;
        -h | --home)
            export MYCELIO_HOME="$2"
            shift # past argument
            shift # past value
            ;;
        *)                     # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift              # past argument
            ;;
        esac
    done
}

function _initialize_environment() {
    _parse_arguments "$@"

    # Need to setup environment variables before anything else
    setup_environment

    # Note below that we use 'whoami' since 'USER' variable is not set for
    # scheduled tasks on Synology.

    echo "╔▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
    echo "║       • Root: '$MYCELIO_ROOT'"
    echo "║         User: '$(whoami)'"
    echo "║         Home: '$MYCELIO_HOME'"
    echo "║           OS: '$MYCELIO_OS' ($MYCELIO_ARCH)"
    echo "║        Shell: '$MYCELIO_SHELL'"
    echo "║  Debug Trace: '$MYCELIO_DEBUG_TRACE_FILE'"
    echo "╚▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"

    # Make sure we have the appropriate permissions to write to home temporary folder
    # otherwise much of this initialization will fail.
    mkdir -p "$MYCELIO_TEMP"
    if ! touch "$MYCELIO_TEMP/.test"; then
        log_error "[mycelio] ERROR: Missing permissions to write to temp folder: '$MYCELIO_TEMP'"
        return 1
    else
        rm -rf "$MYCELIO_TEMP/.test"
    fi

    if [ "$MYCELIO_ARG_CLEAN" = "1" ]; then
        if rm -rf "$MYCELIO_TEMP" >/dev/null 2>&1; then
            echo "[mycelio] Removed workspace temporary files to force a rebuild."
        else
            echo "[mycelio] Partially removed workspace temporary files to force a rebuild."
        fi
    fi

    mkdir -p "$MYCELIO_HOME/.config/fish"
    mkdir -p "$MYCELIO_HOME/.ssh"
    mkdir -p "$MYCELIO_HOME/.local/share"
    mkdir -p "$MYCELIO_TEMP"

    if [ "$MYCELIO_OS" = "windows" ] && [ -d "/etc/" ]; then
        # Make sure we have permission to touch the folder
        if touch --no-create "/etc/fstab" >/dev/null 2>&1; then
            if [ ! -f "/etc/passwd" ]; then
                mkpasswd -l -c >"/etc/passwd"
            fi

            if [ ! -f "/etc/group" ]; then
                mkgroup -l -c >"/etc/group"
            fi

            if [ ! -L "/etc/nsswitch.conf" ]; then
                if [ -f "/etc/nsswitch.conf" ]; then
                    mv "/etc/nsswitch.conf" "/etc/nsswitch.conf.bak"
                fi

                if ln -s "$MYCELIO_ROOT/source/windows/msys/nsswitch.conf" "/etc/nsswitch.conf" >/dev/null 2>&1; then
                    echo "Updated 'nsswitch.conf' with custom version."
                else
                    log_error "Unable to create symbolic link to 'nsswitch.conf' likely due to permission errors."
                fi
            fi
        fi
    fi

    task_group "Initialize Git Config" initialize_gitconfig
    if ! task_group "Update Git Repositories" update_repositories; then
        echo "WARNING: Unable to update Git repositories. Continuing setup."
    fi

    if [ "$MYCELIO_OS" = "linux" ] || [ "$MYCELIO_OS" = "windows" ]; then
        initialize_linux "$@"
    elif [ "$MYCELIO_OS" = "darwin" ]; then
        initialize_macos "$@"
    fi

    # Always run configure step as it creates links ('stows') important profile
    # setup scripts to home directory.
    configure_linux "$@"

    if ! load_profile; then
        log_error "Failed to reload profile."
    fi

    if [ "${BASH_VERSION_MAJOR:-0}" -ge 4 ]; then
        _supports_neofetch=1
    elif [ "${BASH_VERSION_MAJOR:-0}" -ge 3 ] && [ "${BASH_VERSION_MINOR:-0}" -ge 2 ]; then
        _supports_neofetch=1
    else
        _supports_neofetch=0
    fi

    if [ -x "$(command -v neofetch)" ] && [ "$_supports_neofetch" = "1" ]; then
        echo ""
        if neofetch; then
            _displayed_details=1
        fi
    fi

    if [ ! "${_displayed_details:-}" = "1" ]; then
        echo "Initialized '${MYCELIO_OS:-UNKNOWN}' machine."
    fi

    return 0
}

function use_mycelio_library() {
    export MYCELIO_SCRIPT_NAME="${1:-mycelio_library}"

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

function initialize_environment() {
    if _initialize_environment "$@"; then
        _return_code=0
    else
        _return_code=$?
    fi

    _remove_error_handling

    return $_return_code
}
