#!/usr/bin/env bash
#
# Usage: ./init.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

function __print_stack() {
    if [ -n "${BASH:-}" ]; then
        callstack_end=${#FUNCNAME[@]}
        index=0

        local callstack=""
        while ((index < callstack_end)); do
            callstack+=$(printf '  >    %s:%d: %s()\\n' "${BASH_SOURCE[$index]}" "${BASH_LINENO[$index]}" "${FUNCNAME[$((index + 1))]}")
            ((++index))
        done

        echo "  > Callstack:"
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

    # Stop tracing once we hit the error
    set +o xtrace || true

    _line=${_mycelio_dbg_last_line:-}

    if [ "${_line:-}" = "" ]; then
        _line="${1:-}"
    fi

    if [ "${_line:-}" = "" ]; then
        _line="[undefined]"
    fi

    # First argument is always the line number even if unused
    shift

    echo "--------------------------------------"

    if [ "${MYCELIO_DEBUG_TRAP_ENABLED:-}" = "1" ]; then
        echo "Error on line #$_line:"
    fi

    # This only exists in a few shells e.g. bash
    # shellcheck disable=SC2039,SC3044
    if _caller="$(caller 2>&1)"; then
        echo "  > Caller: '${_caller:-UNKNOWN}'"
    fi

    echo "  > Command: '${BASH_COMMAND:-UNKNOWN}'"
    echo "  > Code: '${_retval:-}'"

    __print_stack "$@"

    # We always exit immediately on error
    __safe_exit ${_retval:-1}
}

function _setup_error_handling() {
    export MYCELIO_DEBUG_TRAP_ENABLED=0

    # We only output command on Bash because by default "-x" will output to 'stderr' which
    # results in an error on CI as it's used to make sure we have clean output. On Bash we
    # can override to to go to a new file descriptor.
    if [ -z "${BASH:-}" ]; then
        echo "No error handling enabled. Only supported in bash shell."
    else
        # Disable xtrace and re-enable below if desired
        set +o xtrace || true

        set -o errexit
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
        trap '__trap_error "$LINENO" ${BASH_LINENO[@]+"${BASH_LINENO[@]}"}' ERR

        _enable_trace=0
        _bash_debug=0

        # Redirect only supported in Bash versions after 4.1
        if [ "$BASH_VERSION_MAJOR" -eq 4 ] && [ "$BASH_VERSION_MINOR" -ge 1 ]; then
            _enable_trace=1
        elif [ "$BASH_VERSION_MAJOR" -gt 4 ]; then
            _enable_trace=1
        fi

        if [ "$_enable_trace" = "1" ]; then
            trap '[[ ${FUNCNAME:-} = "__trap_error" ]] || {
                    _mycelio_dbg_last_line=${_mycelio_dbg_line:-};
                    _mycelio_dbg_line=${LINENO:-};
                }' DEBUG

            _bash_debug=1

            # Error tracing (sub shell errors) only work properly in version >=4.0 so
            # we enable here as well. Otherwise errors in subshells can result in ERR
            # trap being called e.g. _my_result="$(errorfunc test)"
            set -o errtrace

            export MYCELIO_DEBUG_TRAP_ENABLED=1
        fi

        MYCELIO_DEBUG_TRACE_FILE=""

        if [ "$_bash_debug" = "1" ] && [ "$_enable_trace" = "1" ]; then
            MYCELIO_DEBUG_TRACE_FILE="$MYCELIO_HOME/.logs/init.xtrace.log"
            mkdir -p "$MYCELIO_HOME/.logs"
            exec 19>"$MYCELIO_DEBUG_TRACE_FILE"
            export BASH_XTRACEFD=19
            set -o xtrace
        fi

        export MYCELIO_DEBUG_TRACE_FILE
    fi
}

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
function _get_real_path() {
    _pwd="$(pwd)"
    _input_path="$1"

    cd "$(dirname "$_input_path")" || true

    _link=$(readlink "$(basename "$_input_path")")
    while [ "$_link" ]; do
        cd "$(dirname "$_link")" || true
        _link=$(readlink "$(basename "$_input_path")")
    done

    _real_path="$(pwd)/$(basename "$_input_path")"
    cd "$_pwd" || true

    echo "$_real_path"
}

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
    if ! _command_exists "sudo"; then
        return 2
    else
        # -n -> 'non-interactive'
        # -v -> 'validate'
        if _prompt="$(sudo -nv 2>&1)"; then
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
                if dscl . -authonly "$(whoami)" "" >/dev/null 2>&1; then
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

function initialize_gitconfig() {
    _git_config="$MYCELIO_HOME/.gitconfig"
    rm -f "$_git_config"
    unlink "$_git_config" >/dev/null 2>&1 || true
    echo "[include]" >"$_git_config"
    echo "    path = $MYCELIO_ROOT/git/.gitconfig_common" >>"$_git_config"
    echo "    path = $MYCELIO_ROOT/git/.gitconfig_linux" >>"$_git_config"

    if _is_windows; then
        echo "    path = $MYCELIO_ROOT/git/.gitconfig_linux" >>"$_git_config"
    fi

    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        echo "    path = $MYCELIO_ROOT/git/.gitconfig_wsl" >>"$_git_config"
        echo "Added WSL include to '.gitconfig' file."
    fi

    echo "Created custom '.gitconfig' with include directives."
}

function install_hugo {
    _local_bin="$MYCELIO_HOME/.local/bin"
    _go_exe="$MYCELIO_GOBIN/go"
    _hugo_exe="$MYCELIO_GOBIN/hugo"

    if [ -f "$_hugo_exe" ]; then
        echo "✔ 'hugo' site builder already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ]; then
        echo "❌ Failed to install 'hugo' site builder. Required 'git' tool missing."
        return 1
    fi

    if [ ! -f "$_go_exe" ]; then
        echo "❌ Failed to install 'hugo' site builder. Missing 'go' compiler: '$_go_exe'"
        return 2
    fi

    if [ -f "$_go_exe" ]; then
        _tmp_hugo="$MYCELIO_TEMP/hugo"
        mkdir -p "$_tmp_hugo"

        rm -rf "$_tmp_hugo"
        git -c advice.detachedHead=false clone -b "v0.87.0" "https://github.com/gohugoio/hugo.git" "$_tmp_hugo"

        if (
            cd "$_tmp_hugo"

            # We only modify the environment for this subshell and that is the expectation
            # so we ignore the warnings here.
            # shellcheck disable=SC2030
            export GOROOT="$MYCELIO_GOROOT"
            # shellcheck disable=SC2030
            export GOBIN="$MYCELIO_GOBIN"

            # No support for GCC on Synology so not able to build extended features
            if ! uname -a | grep -q "synology"; then
                export CGO_ENABLED="1"
                echo "##[cmd] $_go_exe install --tags extended"
                "$_go_exe" install --tags extended
            else
                export CGO_ENABLED="0"
                echo "##[cmd] $_go_exe install"
                "$_go_exe" install
            fi
        ); then
            echo "Successfully installed 'hugo' site builder."
        else
            echo "Failed to install 'hugo' site builder."
        fi
    fi

    if [ ! -f "$_hugo_exe" ]; then
        echo "❌ Failed to install 'hugo' static site builder."
        return 3
    fi

    "$_hugo_exe" version

    return 0
}

function install_go {
    _local_root="$MYCELIO_HOME/.local"
    _local_go_root="$_local_root/go"
    _go_exe="$_local_go_root/bin/go"
    _go_requires_update=0

    if [ -f "$_go_exe" ] && _go_version="$("$_go_exe" version 2>&1 | (
        read -r _ _ v _
        echo "${v#go}"
    ))"; then
        _go_version_minor=$(echo "$_go_version" | cut -d. -f2)
        if [ "$_go_version_minor" -lt 17 ]; then
            _go_requires_update=1
        fi
    else
        _go_requires_update=1
    fi

    if [ "$_go_requires_update" = "1" ]; then
        _go_version="1.17"
        _go_compiled=0

        # https://golang.org/doc/install/source
        if [ -x "$(command -v go)" ] && [ -x "$(command -v gcc)" ] && [ -x "$(command -v make)" ]; then
            _go_src_archive="$MYCELIO_TEMP/go.tgz"
            wget --quiet -O "$_go_src_archive" "https://dl.google.com/go/go$_go_version.src.tar.gz"

            echo "Extracting 'go' source: '$_go_src_archive'"
            tar -C "$_local_root" -xzf "$_go_src_archive"
            rm "$_go_src_archive"

            echo "Compiling 'go' from source: '$_local_go_root/src'"
            if (
                cd "$_local_go_root/src"

                GOHOSTOS="$MYCELIO_OS"
                export GOHOSTOS

                GOARCH="$MYCELIO_ARCH"
                export GOARCH

                GOARM="$MYCELIO_ARM"
                export GOARM

                GOHOSTARCH="$MYCELIO_ARCH"
                export GOHOSTARCH

                if [ -x "$(command -v cygpath)" ]; then
                    if ! cmd /c "make.bat"; then
                        exit 1
                    fi
                elif ! ./make.bash; then
                    exit 1
                fi

                if [ ! -f "$_go_exe" ]; then
                    exit 2
                fi

                # Pre-compile the standard library, just like the official binary release tarballs do
                if "$_go_exe" install std; then
                    echo "Pre-compiled 'go' standard library."
                fi
            ); then
                echo "Successfully compiled 'go' from source."
            else
                echo "Failed to compile 'go' from source."
            fi

            # Remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
            rm -rf "$_local_go_root/pkg/*/cmd"
            rm -rf "$_local_go_root/pkg/bootstrap"
            rm -rf "$_local_go_root/pkg/obj"
            rm -rf "$_local_go_root/pkg/tool/*/api"
            rm -rf "$_local_go_root/pkg/tool/*/go_bootstrap "
            rm -rf "$_local_go_root/src/cmd/dist/dist"
        else
            echo "Missing required tools to compile 'go' from source."
        fi

        if [ "$_go_compiled" = "0" ]; then
            if _uname_output="$(uname -s 2>/dev/null)"; then
                case "${_uname_output}" in
                Linux*)
                    _go_archive="go$_go_version.linux-$MYCELIO_ARCH.tar.gz"
                    ;;
                Darwin*)
                    _go_archive="go$_go_version.darwin-$MYCELIO_ARCH.tar.gz"
                    ;;
                esac
            fi

            # Install Golang
            if [ -z "$_go_archive" ]; then
                echo "Unsupported platform for installing 'go' language."
            else
                echo "Downloading archive: 'https://dl.google.com/go/$_go_archive'"
                curl -o "$MYCELIO_TEMP/$_go_archive" "https://dl.google.com/go/$_go_archive"
                if [ ! -f "$MYCELIO_TEMP/$_go_archive" ]; then
                    echo "Failed to download 'go' archive."
                else
                    echo "Downloaded archive: '$_go_archive'"

                    _go_tmp="$MYCELIO_TEMP/go"
                    rm -rf "${_go_tmp:?}/"
                    if tar -xf "$MYCELIO_TEMP/$_go_archive" --directory "$MYCELIO_TEMP"; then
                        echo "Extracted 'go' archive: '$_go_tmp'"

                        mkdir -p "$_local_go_root/"
                        rm -rf "${_local_go_root:?}/"
                        cp -rf "$_go_tmp" "$_local_go_root"
                        echo "Updated 'go' install: '$_local_go_root'"
                    else
                        echo "❌ Failed to update 'go' install."
                    fi

                    rm -rf "$_go_tmp"
                    echo "Removed temporary 'go' files: '$_go_tmp'"
                fi
            fi
        fi
    fi

    if [ -f "$_go_exe" ] && _version=$("$_go_exe" version); then
        echo "✔ $_version"
    else
        echo "❌ Failed to install 'go' language."
    fi
}

function _stow_internal() {
    _package="$1"
    _source="$2"
    _target="$3"

    if [ -f "$_source" ] || [ -d "$_source" ]; then
        if [ "${MYCELIO_REFRESH_ENVIRONMENT:-}" = "1" ]; then
            _remove=0

            if [ -f "$_target" ]; then
                _remove=1
            elif [ -L "$_target" ] && [ -d "$_target" ]; then
                _remove=1
            fi

            if [ "$_remove" = "1" ]; then
                rm -rf "$_target"
                echo "REMOVED: '$_target'"
            fi
        fi

        if [ ! -f "$_stow_bin" ]; then
            if [ -f "$_source" ]; then
                mkdir -p "$(dirname "$_target")"
            fi

            ln -s "$_source" "$_target"
            echo "✔ Stowed '$_package' target: '$_target'"
        fi
    fi
}

function _stow() {
    _stow_bin="$MYCELIO_ROOT/source/stow/bin/stow"

    _package="$1"
    _target_path="$MYCELIO_HOME"

    if [ ! -x "$(command -v git)" ]; then
        echo "❌ Failed to stow '$_package' as git is required."
        return 1
    elif [ -d "$MYCELIO_ROOT/.git" ]; then
        git -C "$MYCELIO_ROOT" ls-tree --name-only -r HEAD "$_package" | while IFS= read -r line; do
            _source="${MYCELIO_ROOT%/}/$line"
            _target="${_target_path%/}/${line/$_package\//}"
            _stow_internal "$_package" "$_source" "$_target"
        done
    else
        find "$MYCELIO_ROOT" -maxdepth 1-type f -print0 | while IFS= read -r -d $'\0' file; do
            _source="$file"
            _target="$HOME/${file//$_root_dir/}"
            _stow_internal "$_package" "$_source" "$_target"
        done
    fi

    if [ -f "$_stow_bin" ]; then
        # NOTE: We filter out spurious 'find_stowed_path' error due to https://github.com/aspiers/stow/issues/65
        _stow_args=(--dir="$MYCELIO_ROOT" --target="$_target_path" --verbose)

        if [ "${MYCELIO_REFRESH_ENVIRONMENT:-}" = "1" ]; then
            _stow_args+=(--restow)
        fi

        echo "##[cmd] stow ${_stow_args[*]} $*"
        if "$_stow_bin" "${_stow_args[@]}" "$_package" 2>&1 | grep -v "BUG in find_stowed_path"; then
            echo "✔ Stowed : '$_package'"
        else
            echo "❌ Stow failed: '$_package'"
            return 3
        fi
    fi

    return 0
}

function configure_linux() {
    _stow "$@" linux
    _stow "$@" bash
    _stow "$@" zsh
    _stow "$@" fonts
    _stow "$@" ruby
    _stow "$@" vim

    # We use built-in VSCode syncing so disabled the stow operation for VSCode
    # _stow vscode

    # We intentionally stow 'fish' config first to populate the directories
    # and then we create additional links (e.g. keybindings) and download
    # the fish package manager fundle, see https://github.com/danhper/fundle
    _stow "$@" fish

    mkdir -p "$MYCELIO_HOME/.config/fish/functions"

    # Link fzf (https://github.com/junegunn/fzf) key bindings after we have tried to
    # install it.
    _binding_link="$MYCELIO_HOME/.config/fish/functions/fzf_key_bindings.fish"
    _binding_file="/usr/local/opt/fzf/shell/key-bindings.fish"
    if [ -f "$_binding_file" ] && [ ! -f "$_binding_link" ]; then
        ln -s "$_binding_file" "$_binding_link"
    fi

    if [ ! -f "$MYCELIO_HOME/.config/fish/functions/fundle.fish" ]; then
        wget "https://git.io/fundle" -O "$MYCELIO_HOME/.config/fish/functions/fundle.fish" || true
        if [ -f "$MYCELIO_HOME/.config/fish/functions/fundle.fish" ]; then
            chmod a+x "$MYCELIO_HOME/.config/fish/functions/fundle.fish"
        fi
    fi

    if [ -x "$(command -v fish)" ]; then
        if [ ! -f "$MYCELIO_HOME/.config/fish/functions/fundle.fish" ]; then
            echo "❌ Fundle not installed in home directory: '$MYCELIO_HOME/.config/fish/functions/fundle.fish'"
        else
            if fish -c "fundle install"; then
                echo "✔ Installed 'fundle' package manager for fish."
            else
                echo "❌ Failed to install 'fundle' package manager for fish."
            fi
        fi
    else
        echo "Skipped fish shell initialization as it is not installed."
    fi

    _gnupg_config_root="$MYCELIO_HOME/.gnupg"
    _gnupg_templates_root="$MYCELIO_ROOT/templates/.gnupg"
    mkdir -p "$_gnupg_config_root"

    rm -f "$_gnupg_config_root/gpg-agent.conf"
    cp "$_gnupg_templates_root/gpg-agent.conf" "$_gnupg_config_root/gpg-agent.conf"
    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        echo "pinentry-program \"/mnt/c/Program Files (x86)/GnuPG/bin/pinentry-basic.exe\"" >>"$_gnupg_config_root/gpg-agent.conf"
    fi
    echo "Created config from template: '$_gnupg_config_root/gpg-agent.conf'"

    rm -f "$_gnupg_config_root/gpg.conf"
    cp "$_gnupg_templates_root/gpg.conf" "$_gnupg_config_root/gpg.conf"
    echo "Created config from template: '$_gnupg_config_root/gpg.conf'"
}

function install_micro_text_editor() {
    mkdir -p "$MYCELIO_HOME/.local/bin/"

    if [ "$MYCELIO_OS" == "windows" ]; then
        _micro_exe="micro.exe"
    else
        _micro_exe="micro"
    fi

    if [ "${MYCELIO_REFRESH_ENVIRONMENT:-}" = "1" ]; then
        rm -f "$MYCELIO_HOME/.local/bin/$_micro_exe"
    fi

    # Install micro text editor. It is optional so ignore failures
    if [ -f "$MYCELIO_HOME/.local/bin/$_micro_exe" ]; then
        echo "✔ micro text editor already installed."
        return 0
    fi

    _tmp_micro="$MYCELIO_TEMP/micro"
    mkdir -p "$_tmp_micro"
    rm -rf "$_tmp_micro"
    git -c advice.detachedHead=false clone -b "v2.0.10" "https://github.com/zyedidia/micro" "$_tmp_micro"

    if (
        cd "$_tmp_micro"
        make build
        mv "$_micro_exe" "$MYCELIO_HOME/.local/bin/"
    ); then
        echo "✔ Successfully compiled micro text editor."
    else
        if (
            mkdir -p "$MYCELIO_HOME/.local/bin/"
            cd "$MYCELIO_HOME/.local/bin/"
            curl "https://getmic.ro" | bash
        ); then
            echo "[mycelio] Successfully installed 'micro' text editor."
        else
            echo "[mycelio] WARNING: Failed to install 'micro' text editor."
            return 2
        fi
    fi

    return 0
}

function initialize_linux() {
    dotenv="$MYCELIO_HOME/.env"
    if [ ! -f "$dotenv" ]; then
        echo "# Generated by Mycelio dotfiles project." >"$dotenv"
        echo "" >>"$dotenv"
    fi

    if ! grep -q "MYCELIO_ROOT" "$dotenv"; then
        echo "MYCELIO_ROOT=$MYCELIO_ROOT" >>"$dotenv"
        echo "Added 'MYCELIO_ROOT' to dotenv file: '$dotenv'"
    fi

    if uname -a | grep -q "synology"; then
        echo "Skipped installing dependencies. Not supported on Synology platform."
    elif [ -x "$(command -v pacman)" ]; then
        # Primary driver for these dependencies is 'stow' but they are generally useful as well
        echo "[mycelio] Installing minimal packages to build dependencies on Windows using MSYS2."

        # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
        rm -f /var/lib/pacman/db.lck

        pacman -Syu --quiet --noconfirm
        pacman -S --quiet --noconfirm --needed \
            msys2-keyring curl wget unzip \
            git gawk \
            fish tmux \
            base-devel mingw-w64-x86_64-gcc make autoconf automake1.16 automake-wrapper libtool \
            perl mingw-w64-x86_64-go

        if [ -f "/etc/pacman.d/gnupg/" ]; then
            rm -rf "/etc/pacman.d/gnupg/"
        fi

        pacman-key --quiet --init
        pacman-key --quiet --populate msys2

        # Long version of '-Syuu' gets fresh package databases from server and
        # upgrades the packages while allowing downgrades '-uu' as well if needed.
        pacman --quiet --sync --refresh -uu --noconfirm
    elif [ -x "$(command -v apk)" ]; then
        if [ ! -x "$(command -v sudo)" ]; then
            apk update
            apk add sudo
        else
            sudo apk update
        fi

        sudo apk add \
            tzdata git wget curl unzip xclip \
            build-base gcc g++ make musl-dev go \
            stow tmux neofetch fish \
            python3 py3-pip \
            fontconfig openssl gnupg
    elif [ -x "$(command -v apt-get)" ]; then
        if [ ! -x "$(command -v sudo)" ]; then
            apt-get update
            apt-get install -y sudo
        else
            sudo apt-get update
        fi

        # Needed to prevent interactive questions during 'tzdata' install, see https://stackoverflow.com/a/44333806
        sudo ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime >/dev/null 2>&1

        DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y --no-install-recommends \
            tzdata git wget curl unzip xclip \
            software-properties-common build-essential gcc g++ make automake autoconf golang \
            texinfo \
            stow tmux neofetch fish \
            python3 python3-pip \
            fontconfig

        if [ -x "$(command -v dpkg-reconfigure)" ]; then
            sudo dpkg-reconfigure --frontend noninteractive tzdata
        fi
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped install of Python setup for root user."
    else
        if [ -x "$(command -v python3)" ]; then
            python3 -m pip install --user --upgrade pip

            # Could install with 'snapd' but there are issues with 'snapd' on WSL so to maintain
            # consistency between platforms and not install hacks we just use 'pip3' instead. For
            # details on the issue, see https://github.com/microsoft/WSL/issues/5126
            python3 -m pip install --user pre-commit

            echo "Upgraded 'pip3' and installed 'pre-commit' package."
        fi
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped install of 'go' and 'hugo' for root user."
    else
        install_go

        # We are counting this as an optional dependency so ignore errors
        install_hugo || true
    fi

    _build_stow

    # Optional dependency so ignore errors
    install_micro_text_editor || true

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped install of 'oh-my-posh' for root user."
    else
        if [ ! -x "$(command -v oh-my-posh)" ]; then
            _local_bin="$MYCELIO_HOME/.local/bin"
            mkdir -p "$_local_bin"

            if [ "$MYCELIO_OS" = "windows" ]; then
                _posh_extension=".exe"
            else
                _posh_extension=""
            fi

            _posh_archive="posh-$MYCELIO_OS-$MYCELIO_ARCH$_posh_extension"
            _posh_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/$_posh_archive"

            if wget --quiet "$_posh_url" -O "$_local_bin/oh-my-posh$_posh_extension"; then
                chmod +x "$_local_bin/oh-my-posh$_posh_extension"
            else
                echo "Unsupported platform for installing 'oh-my-posh' extension."
            fi
        fi

        font_base_name="JetBrains Mono"
        font_base_filename=${font_base_name// /}
        font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$font_base_filename.zip"
        _fonts_path="$MYCELIO_HOME/.fonts"

        if [ ! -f "$_fonts_path/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
            mkdir -p "$_fonts_path"
            wget --quiet "$font_url" -O "$_fonts_path/$font_base_filename.zip"

            if [ -x "$(command -v unzip)" ]; then
                unzip -o "$_fonts_path/$font_base_filename.zip" -d "$_fonts_path"
            elif [ -x "$(command -v 7z)" ]; then
                7z e "$_fonts_path/$font_base_filename.zip" -o"$_fonts_path" -r
            else
                echo "Neither 'unzip' nor '7z' commands available to extract fonts."
            fi

            chmod u+rw ~/.fonts
            rm -f "$_fonts_path/$font_base_filename.zip"

            if [ -x "$(command -v fc-cache)" ]; then
                if fc-cache -fv >/dev/null 2>&1; then
                    echo "Flushed font cache."
                else
                    echo "Failed to flush font cache."
                fi
            else
                echo "Unable to flush font cache as 'fc-cache' is not installed"
            fi
        fi

        if [ ! -f "$MYCELIO_HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
            _posh_themes="$MYCELIO_HOME/.poshthemes"
            mkdir -p "$_posh_themes"
            wget --quiet "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -O "$_posh_themes/themes.zip"

            if [ -x "$(command -v unzip)" ]; then
                unzip -o "$_posh_themes/themes.zip" -d "$_posh_themes"
            elif [ -x "$(command -v 7z)" ]; then
                7z e "$_posh_themes/themes.zip" -o"$_posh_themes" -r
            else
                echo "Neither 'unzip' nor '7z' commands available to extract oh-my-posh themes."
            fi

            chmod u+rw ~/.poshthemes/*.json
            rm -f "$_posh_themes/themes.zip"
        fi
    fi

    if [ ! -d "$MYCELIO_HOME/.asdf" ]; then
        if [ -x "$(command -v git)" ]; then
            git -c advice.detachedHead=false clone "https://github.com/asdf-vm/asdf.git" "$MYCELIO_HOME/.asdf" --branch v0.8.1
        else
            echo "Skipped install of 'asdf' as git is not installed."
        fi
    fi
}

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#
function _build_stow() {
    if [ "${MYCELIO_REFRESH_ENVIRONMENT:-}" = "1" ]; then
        rm -f "$MYCELIO_ROOT/source/stow/bin/stow"
        rm -f "$MYCELIO_HOME/.cpan/CPAN/MyConfig.pm"
    fi

    if [ -x "$(command -v cpan)" ]; then
        # If configuration file does not exist yet then we automate configuration with
        # answers to standard questions. These may become invalid with newer versions.
        if [ ! -f "$MYCELIO_HOME/.cpan/CPAN/MyConfig.pm" ]; then
            (
                echo "yes"
                echo ""
                echo "no"
                echo "exit"
            ) | cpan
        fi

        # Install '-i' but skip tests '-T' for the modules we need. We skip tests in part because
        # it is faster but also because tests in 'Test::Output' causes consistent hangs
        # in MSYS2, see https://rt-cpan.github.io/Public/Bug/Display/64319/
        cpan -i -T YAML Test::Output CPAN::DistnameInfo 2>&1 | awk '{ print "[stow.cpan]", $0 }'
    else
        echo "[stow] WARNING: Package manager 'cpan' not found. There will likely be missing perl dependencies."
    fi

    if [ ! -f "$MYCELIO_ROOT/source/stow/configure.ac" ] && [ -x "$(command -v git)" ]; then
        git -C "$MYCELIO_ROOT" submodule update --init --recursive
        echo "Updated submodules due to missing 'stow' source."
    fi

    if [ ! -f "$MYCELIO_ROOT/source/stow/configure.ac" ]; then
        echo "❌ 'stow' source not available: '$MYCELIO_ROOT/source/stow'"
    elif [ -f "$MYCELIO_ROOT/source/stow/bin/stow" ]; then
        echo "✔ Custom 'stow' binary already built from source."
    elif (
        # Move to source directory and start install.
        cd "$MYCELIO_ROOT/source/stow" || true
        autoreconf --install --verbose 2>&1 | awk '{ print "[stow.autoreconf]", $0 }'

        # We want a local install
        ./configure --prefix="" 2>&1 | awk '{ print "[stow.configure]", $0 }'

        # Documentation part is expected to fail but we can ignore that
        make --keep-going --ignore-errors 2>&1 | awk '{ print "[stow.make]", $0 }'

        rm -f "./configure~"
        git checkout -- "./aclocal.m4" || true
    ); then
        echo "✔ Successfully built 'stow' from source."
    else
        echo "❌ Failed to build 'stow' from source."
    fi
}

function initialize_macos() {
    install_macos_apps

    # We need to do this after we install macOS apps as it installs some
    # dependencies needed for this step.
    initialize_linux

    configure_macos_dock
    configure_macos_finder

    # We pass in 'stow' arguments
    configure_macos_apps "$@"
    configure_macos_system
}

function install_macos_apps() {
    if ! [ -x "$(command -v brew)" ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi

    brew upgrade

    if ! brew bundle; then
        echo "Install with 'brew' failed with errors, but continuing."
    fi

    cask upgrade

    #
    # We install these seprately as they can fail if already installed.
    #
    if [ ! -d "/Applications/Google Chrome.app" ]; then
        brew install --cask "google-chrome" || true
    fi

    # https://github.com/JetBrains/JetBrainsMono
    if [ ! -f "/Users/$(whoami)/Library/Fonts/JetBrainsMono-BoldItalic.ttf" ]; then
        brew install --cask "font-jetbrains-mono" || true
    fi

    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        brew install --cask "visual-studio-code" || true
    fi

    # If user is not signed into the Apple store, notify them and skip install
    if ! mas account >/dev/null; then
        echo "Skipped app store installs. Please open App Store and sign in using your Apple ID."
    else
        # Powerful keep-awake utility, see https://apps.apple.com/us/app/amphetamine/id937984704
        # 'Amphetamine', id: 937984704
        mas install 937984704 || true
    fi

    echo "Installed dependencies with 'brew' package manager."
}

function configure_macos_apps() {
    mkdir -p "$MYCELIO_HOME/Library/Application\ Support/Code"

    _stow "$@" macos

    for f in .osx/*.plist; do
        [ -e "$f" ] || continue

        echo "Importing settings from $f"
        plist=$(basename -s .plist "$f")
        echo defaults delete "$plist" >/dev/null || true
        echo defaults import "$plist" "$f"
    done

    echo "Configured applications with settings."
}

function configure_macos_dock() {
    # Set the icon size of Dock items to 36 pixels
    defaults write com.apple.dock tilesize -int 36
    # Wipe all (default) app icons from the Dock
    defaults write com.apple.dock persistent-apps -array
    # Disable Dashboard
    defaults write com.apple.dashboard mcx-disabled -bool true
    # Don't show Dashboard as a Space
    defaults write com.apple.dock dashboard-in-overlay -bool true
    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool false
    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0
    # Disable the Launchpad gesture (pinch with thumb and three fingers)
    defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

    ## Hot corners
    ## Possible values:
    ##  0: no-op
    ##  2: Mission Control
    ##  3: Show application windows
    ##  4: Desktop
    ##  5: Start screen saver
    ##  6: Disable screen saver
    ##  7: Dashboard
    ## 10: Put display to sleep
    ## 11: Launchpad
    ## 12: Notification Center
    ## Bottom right screen corner → Start screen saver
    defaults write com.apple.dock wvous-br-corner -int 5
    defaults write com.apple.dock wvous-br-modifier -int 0

    echo "Configured Dock."
}

function configure_macos_finder() {
    # Save screenshots to Downloads folder
    defaults write com.apple.screencapture location -string "${MYCELIO_HOME}/Downloads"
    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    # Set home directory as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${MYCELIO_HOME}/"
    # Display full POSIX path as Finder window title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: 'icnv', 'clmv', 'Flwv'
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    echo "Configured Finder."
}

function configure_macos_system() {
    # Disable Gatekeeper entirely to get rid of "Are you sure you want to open this application?" dialog
    if [ "${MYCELIO_INTERACTIVE:-}" = "1" ]; then
        echo "[mycelio] This will disable Gatekeeper questions (e.g., are you sure you want"
        echo "          to open this application?). Enter system password:"
        sudo spctl --master-disable
    fi

    defaults write -g com.apple.mouse.scaling 3.0                              # mouse speed
    defaults write -g com.apple.trackpad.scaling 2                             # trackpad speed
    defaults write -g com.apple.trackpad.forceClick 1                          # tap to click
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 1 # three finger drag
    defaults write -g ApplePressAndHoldEnabled -bool false                     # repeat keys on hold

    echo "Configured system settings."
}

#
# Minimal set of required environment variables that the rest of the script relies
# on heavily to operate including setting up error handling. It is therefore critical
# that this function is error free and handles all edge cases for all supported
# platforms.
#
function _setup_environment() {
    if [ -n "${BASH:-}" ]; then
        BASH_VERSION_MAJOR=$(echo "$BASH_VERSION" | cut -d. -f1)
        BASH_VERSION_MINOR=$(echo "$BASH_VERSION" | cut -d. -f2)
    else
        BASH_VERSION_MAJOR=0
        BASH_VERSION_MINOR=0
    fi

    export BASH_VERSION_MAJOR
    export BASH_VERSION_MINOR

    MYCELIO_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
    export MYCELIO_ROOT

    # Get home path which is hopefully in 'HOME' but if not we use the parent
    # directory of this project as a backup.
    HOME=${HOME:-"$(cd "$MYCELIO_ROOT" && cd ../ && pwd)"}
    export HOME

    export MYCELIO_HOME="$HOME"
}

function main() {
    # Need to setup environment variables before anything else
    _setup_environment

    _setup_error_handling

    if [ -f "$MYCELIO_ROOT/linux/.profile" ]; then
        # shellcheck source=linux/.profile
        . "$MYCELIO_ROOT/linux/.profile"
    fi

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
        MYCELIO_ARCH='arm' MYCELIO_ARM='6'
        ;;
    'armv7')
        MYCELIO_ARCH='arm' MYCELIO_ARM='7'
        ;;
    'armv7l')
        # Raspberry PI
        MYCELIO_ARCH='arm' MYCELIO_ARM='7'
        ;;
    'aarch64')
        MYCELIO_ARCH='arm64'
        ;;
    'x86')
        MYCELIO_ARCH='386' MYCELIO_386='softfloat'
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

    uname_system="$(uname -s)"
    case "${uname_system}" in
    Linux*)
        export MYCELIO_OS='linux'
        ;;
    Darwin*)
        export MYCELIO_OS='darwin'
        ;;
    CYGWIN*)
        export MYCELIO_OS='windows'
        ;;
    MINGW*)
        export MYCELIO_OS='windows'
        ;;
    MSYS*)
        export MYCELIO_OS='windows'
        ;;
    *)
        export MYCELIO_OS="UNKNOWN:${uname_system}"
        ;;
    esac

    # Assume we are fine with interactive prompts if necessary
    export MYCELIO_INTERACTIVE=1
    export MYCELIO_REFRESH_ENVIRONMENT=0

    POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
        -c | --clean)
            export MYCELIO_REFRESH_ENVIRONMENT=1
            shift # past argument
            ;;
        -y | --yes)
            # Equivalent to the apt-get "assume yes" of '-y'
            export MYCELIO_INTERACTIVE=0
            shift # past value
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

    export MYCELIO_TEMP="$MYCELIO_HOME/.tmp"

    # Note below that we use 'whoami' since $USER variable is not set for
    # scheduled tasks on Synology.

    echo "╔▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
    echo "║       • Root: '$MYCELIO_ROOT'"
    echo "║         User: '$(whoami)'"
    echo "║         Home: '$MYCELIO_HOME'"
    echo "║           OS: '$MYCELIO_OS' ($MYCELIO_ARCH)"
    echo "║  Debug Trace: '$MYCELIO_DEBUG_TRACE_FILE'"
    echo "╚▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"

    # Make sure we have the appropriate permissions to write to home temporary folder
    # otherwise much of this initialization will fail.
    mkdir -p "$MYCELIO_TEMP"
    if ! touch "$MYCELIO_TEMP/.test"; then
        echo "[mycelio] ERROR: Missing permissions to write to temp folder: '$MYCELIO_TEMP'"
        return 1
    else
        rm "$MYCELIO_TEMP/.test"
    fi

    if [ "$MYCELIO_REFRESH_ENVIRONMENT" = "1" ]; then
        rm -rf "$MYCELIO_TEMP"
        echo "[mycelio] Removed workspace temporary files to force a rebuild."
    fi

    mkdir -p "$MYCELIO_HOME/.config/fish"
    mkdir -p "$MYCELIO_HOME/.ssh"
    mkdir -p "$MYCELIO_HOME/.local/share"
    mkdir -p "$MYCELIO_TEMP"

    if [ "$MYCELIO_OS" = "windows" ] && [ -d "/etc/" ]; then
        cp -f "$MYCELIO_ROOT/source/windows/nsswitch.conf" "/etc/nsswitch.conf"
    fi

    initialize_gitconfig

    if [ "$MYCELIO_OS" = "linux" ] || [ "$MYCELIO_OS" = "windows" ]; then
        if ! initialize_linux "$@"; then
            echo "Failed to initialize environment."
        fi
    elif [ "$MYCELIO_OS" = "darwin" ]; then
        if ! initialize_macos "$@"; then
            echo "Failed to initialize macOS environment."
        fi
    fi

    # Always run configure step as it creates links ('stows') important profile
    # setup scripts to home directory.
    configure_linux "$@"

    # Always remove temporary files from home directory
    rm -rf "$MYCELIO_TEMP" || true

    if [ -x "$(command -v apt-get)" ] && [ -x "$(command -v sudo)" ]; then
        DEBIAN_FRONTEND="noninteractive" sudo apt-get autoremove -y

        # Remove intermediate files here to reduce size of Docker container layer
        if [ -f "/.dockerenv" ]; then
            sudo rm -rf /var/lib/apt/lists/*
            sudo rm -rf "/tmp/*"
            sudo rm -rf "/usr/tmp/*"
        fi
    fi

    if [ -f "$MYCELIO_ROOT/linux/.profile" ]; then
        # shellcheck source=linux/.profile
        . "$MYCELIO_ROOT/linux/.profile"
        echo "Refreshed '${MYCELIO_OS}' profile data."
    fi

    _supports_neofetch=0
    if [ "$BASH_VERSION_MAJOR" -ge 4 ]; then
        _supports_neofetch=1
    elif [ "$BASH_VERSION_MAJOR" -ge 3 ] && [ "$BASH_VERSION_MAJOR" -ge 2 ]; then
        _supports_neofetch=1
    fi

    _displayed_details=0

    if [ -x "$(command -v neofetch)" ] && [ "$_supports_neofetch" = "1" ] && neofetch; then
        _displayed_details=1
    fi

    if [ "$_displayed_details" = "1" ]; then
        echo "Initialized '${MYCELIO_OS}' machine."
    fi
}

main "$@"
