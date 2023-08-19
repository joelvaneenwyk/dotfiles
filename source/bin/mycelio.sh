#!/usr/bin/env bash
#
# Usage: ./setup.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

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

function log_error() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::error::$*"
    fi

    echo "❌ $*"
}

# get_file [output_path] [url]
function get_file() {
    output_path=$1
    url=$2
    return_value=0
    if [ -x "$(command -v wget)" ]; then
        if wget -O "$output_path" "$url"; then
            echo "✔ [wget] Downloaded file: '$output_path'"
        else
            return_value=$?
            log_error "[wget] Failed to download file: '$output_path'"
            rm -f "$output_path"
        fi
    elif [ -x "$(command -v curl)" ]; then
        if curl -sSLf -o "$output_path" "$url"; then
            echo "✔ [curl] Downloaded file: '$output_path'"
        else
            return_value=$?
            log_error "[curl] Failed to download file: '$output_path'"
            rm -f "$output_path"
        fi
    else
        log_error "Missing both 'wget' and 'curl'. Failed to download file: '$url'"
        return_value=55
    fi

    return "$return_value"
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
        MYCELIO_DISABLE_TRAP=1
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

function run_command_sudo() {
    _prefix="${1:-}"
    shift

    if _allow_sudo; then
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
    if _allow_sudo; then
        task_group "$_name" run_command "$_prefix" sudo "$@"
    else
        task_group "$_name" run_command "$_prefix" "$@"
    fi
}

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
function _get_real_path() {
    _pwd="$(pwd)"
    _path="$1"
    _offset=""
    _real_path=""

    while :; do
        _base="$(basename "$_path")"

        if ! cd "$(dirname "$_path")" >/dev/null 2>&1; then
            break
        fi

        _link=$(readlink "$_base") || true
        _path="$(pwd)"

        if [ -n "$_link" ]; then
            if [ -f "$_path" ]; then
                _real_path=$(_get_real_path "$_link")
                break
            elif [ -f "$_link" ] || [ -d "$_link" ]; then
                _path="$_link"
            else
                _path="$_path/$_link"
            fi
        else
            _offset="/$_base$_offset"
        fi

        if [ "$_path" = "/" ]; then
            _real_path="$_offset"
            break
        else
            _real_path="$_path$_offset"
        fi
    done

    cd "$_pwd" || true
    echo "$_real_path"

    return 0
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
            "$@"
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

function _load_profile() {
    export MYCELIO_PROFILE_INITIALIZED=0
    export MYCELIO_BASH_PROFILE_INITIALIZED=0

    if [[ $(type -t initialize_interactive_profile) == function ]]; then
        initialize_profile
        initialize_interactive_profile
        echo "[mycelio] Reloaded shell profile."
    elif [ -f "$MYCELIO_ROOT/packages/shell/.profile" ]; then
        # Loading the profile may overwrite the root after it reads the '.env' file
        # so we restore it afterwards.
        _root=$MYCELIO_ROOT

        # shellcheck source=packages/shell/.profile
        source "$MYCELIO_ROOT/packages/shell/.profile"

        # Restore previous root folder
        export MYCELIO_ROOT="${_root:-MYCELIO_ROOT}"

        echo "[mycelio] Loaded shell profile."
    fi

    return 0
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

function _mycelio_get_profile_root() {
    _user_profile="$MYCELIO_HOME"
    _windows_root="$(_get_windows_root)"
    _cmd="$_windows_root/Windows/System32/cmd.exe"

    if [ -x "$(command -v wslpath)" ]; then
        _user_profile="$(wslpath "$(wslvar USERPROFILE)" 2>&1)"
    fi

    if [ -f "$_cmd" ]; then
        if _windows_user_profile="$($_cmd "\/D" "\/S" "\/C" "echo %UserProfile%" 2>/dev/null)"; then
            _win_userprofile_drive="${_windows_user_profile%%:*}:"
            _win_userprofile_dir="${_windows_user_profile#*:}"

            if [ -x "$(command -v findmnt)" ] && _userprofile_mount="$(findmnt --noheadings --first-only --output TARGET "$_win_userprofile_drive")"; then
                _windows_user_profile="$(echo "${_userprofile_mount}${_win_userprofile_dir}" | sed 's/\\/\//g')"
            elif [ -x "$(command -v cygpath)" ]; then
                _windows_user_profile="$(echo "${_windows_user_profile}" | sed 's/\\/\//g')"
                _windows_user_profile="$(cygpath "${_windows_user_profile}")"
            fi
        fi
    fi

    if [ ! -d "$_user_profile" ] && [ -d "$_windows_user_profile" ]; then
        _user_profile="$_windows_user_profile"
    fi

    echo "$_user_profile"
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
    *)
        # Fall through to default error return
        ;;
    esac

    return 1
}

function _stow_internal() {
    _source="$1"
    _target="$2"
    shift 2

    _remove=0

    if [ -f "$_target" ] || [ -d "$_target" ] || [ -L "$_target" ]; then
        _remove=1
    fi

    if [ ! -L "$_target" ]; then
        _real="$(_get_real_path "$_target")"

        # Do not delete files or directories that are actually inside the
        # dot files source directory.
        if [[ "$_real" == *"$MYCELIO_ROOT"* ]]; then
            _remove=0
            echo "🔗 SKIPPED: $_target"
        fi
    fi

    if [ "$_remove" = "1" ]; then
        _name="'$_target'"
        if [ -L "$_target" ]; then
            _name="$_name (link)"
        fi

        if [ -f "$_source" ]; then
            _name="$_name (file)"
            if [[ "$*" == *"--delete"* ]]; then
                if rm -f "$_target" >/dev/null 2>&1; then
                    echo "REMOVED: $_name"
                else
                    echo "SKIPPED: $_name"
                fi
            else
                echo "TARGET: $_name"
            fi
        elif [ -d "$_source" ]; then
            _name="$_name (directory)"
            if [[ "$*" == *"--delete"* ]]; then
                # Remove empty directories in target. It will not delete directories
                # that have files in them.
                if find "$_target" -type d -empty -delete >/dev/null 2>&1 &&
                    rm -df "$_target" >/dev/null 2>&1; then
                    echo "REMOVED: $_name"
                else
                    echo "SKIPPED: $_name"
                fi
            else
                echo "TARGET: $_name"
            fi
        fi
    fi

    if [[ ! "$*" == *"--delete"* ]] && [ ! -f "$_stow_bin" ]; then
        if [ -f "$_source" ]; then
            mkdir -p "$(dirname "$_target")"
        fi

        if [ -f "$_source" ] || [ -d "$_source" ]; then
            if ln -s "$_source" "$_target" >/dev/null 2>&1; then
                echo "✔ Stowed target: '$_target'"
            else
                log_error "Unable to stow target: '$_target'"
            fi
        fi
    fi
}

function _stow() {
    _stow_bin="$MYCELIO_STOW_ROOT/bin/stow"
    _target_path="$MYCELIO_HOME"

    for _package in "$@"; do
        _offset=$"packages/$_package"
        _root="$MYCELIO_ROOT/$_offset"
        if [ -d "$_root" ]; then
            if [ -x "$(command -v git)" ] && [ -d "$MYCELIO_ROOT/.git" ]; then
                # Remove files from directories first and then the directory but only if
                # it is empty.
                {
                    git -C "$MYCELIO_ROOT" ls-tree -r --name-only HEAD "packages/$_package"
                    (git -C "$MYCELIO_ROOT" ls-tree -r -d --name-only HEAD "packages/$_package" | tac)
                } | while IFS= read -r line; do
                    _source="${MYCELIO_ROOT%/}/$line"
                    _target="${_target_path%/}/${line/$_offset\//}"
                    _stow_internal "$_source" "$_target" "$@"
                done
            else
                find "$_root" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
                    _source="$file"
                    _target="$HOME/${file//$_root\//}"
                    _stow_internal "$_source" "$_target" "$@"
                done
            fi
        fi
    done

    if [ -f "$_stow_bin" ] && [[ ! "$*" == *"--delete"* ]]; then
        # NOTE: We filter out spurious 'find_stowed_path' error due to https://github.com/aspiers/stow/issues/65
        _stow_args=("--dir=$MYCELIO_ROOT/packages" "--target=$_target_path" "--verbose")
        _stow_args+=("$@")

        _return_code=0
        if run_command "stow" perl -I "$MYCELIO_STOW_ROOT/lib" "$_stow_bin" "${_stow_args[@]}" 2>&1 | grep -v "BUG in find_stowed_path"; then
            _return_code="${PIPESTATUS[0]}"
        else
            _return_code="${PIPESTATUS[0]}"
        fi

        if [ "$_return_code" = "0" ]; then
            echo "✔ Stow command succeeded."
        else
            log_error "Stow failed."
            return "$_return_code"
        fi
    fi

    return 0
}

function _stow_packages() {
    _stow "$@" shell
    _stow "$@" fonts
    _stow "$@" vim

    # We intentionally stow 'fish' config first to populate the directories
    # and then we create additional links (e.g. keybindings) and download
    # the fish package manager fundle, see https://github.com/danhper/fundle
    _stow "$@" fish

    if [ "${MYCELIO_OS:-}" = "darwin" ]; then
        mkdir -p "$MYCELIO_HOME/Library/Application\ Support/Code"

        # todo : Revisit enabling this at some point after settings are improved
        # _stow "$@" macos
    fi
}

function initialize_gitconfig() {
    _git_config="$MYCELIO_HOME/.gitconfig"

    local windows_root
    windows_root="$(_get_windows_root)"

    if [ ! -f "$_git_config" ] || rm -f "$_git_config"; then
        unlink "$_git_config" >/dev/null 2>&1 || true

        {
            echo "[include]"

            if _is_windows; then
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_common")"
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_linux")"
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_windows")"
                echo "    path = $(cygpath --mixed "$MYCELIO_HOME/.gitconfig_mycelio")"
            elif [ "$MYCELIO_OS" = "darwin" ]; then
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_common"
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_macos"
                echo "    path = $MYCELIO_HOME/.gitconfig_mycelio"
            else
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_common"
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_linux"
                echo "    path = $MYCELIO_HOME/.gitconfig_mycelio"
            fi

            if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_wsl"
            fi
        } >"$_git_config"

        {
            _gpg_paths=(
                "$windows_root/Program Files (x86)/GnuPG/bin/gpg.exe"
                "$(_mycelio_get_profile_root)/scoop/apps/gnupg/current/bin/gpg.exe"
            )
            for _gpg in "${_gpg_paths[@]}"; do
                if [ -f "$_gpg" ] && ! grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
                    _gpg="$(cygpath --mixed "$_gpg")"
                    echo "[gpg]"
                    echo "    program = \"$_gpg\""
                    break
                fi
            done
        } >"$MYCELIO_HOME/.gitconfig_mycelio"

        echo "Created custom '.gitconfig' with include directives."
    fi

    # We only create the local version and never global config at '/etc/gnupg' since typical
    # user does not have access.
    _config_paths=(
        "$MYCELIO_HOME/.gnupg"
    )

    if [ -n "$windows_root" ] && ! grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        _config_paths+=(
            # GPG4Win: homedir
            "$windows_root/Users/$(whoami)/AppData/Roaming/gnupg"

            # GPG4Win: sysconfdir
            "$windows_root/ProgramData/GNU/etc/gnupg"

            # Scoop persistent storage
            "$windows_root/Users/$(whoami)/scoop/persist/gnupg/home"
        )
    fi

    for _config_path in "${_config_paths[@]}"; do
        generate_gnugp_config "$_config_path"
    done

    if _tty="$(tty)"; then
        GPG_TTY="$_tty"
        export GPG_TTY
    fi

    if [ -x "$(command -v gpgconf)" ]; then
        run_command "gpgconf.kill" gpgconf --kill gpg-agent
        if run_command "gpgconf.reload" gpgconf --reload; then
            echo "Reloaded 'gpgconf' tool."
        fi
    fi

    if [ -x "$(command -v gpg-connect-agent)" ]; then
        run_command "gpg.connect" gpg-connect-agent updatestartuptty /bye >/dev/null
    fi
}

function install_hugo {
    _hugo_tmp="$MYCELIO_TEMP/hugo"
    _hugo_exe="$MYCELIO_GOBIN/hugo$MYCELIO_OS_APP_EXTENSION"

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'hugo' install for root user."
        return 0
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_hugo_tmp"
    fi

    if [ -f "$_hugo_exe" ] && "$_hugo_exe" version; then
        echo "✔ 'hugo' site builder already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ]; then
        log_error "Failed to install 'hugo' site builder. Required 'git' tool missing."
        return 1
    fi

    if [ ! -f "$MYCELIO_GOEXE" ]; then
        log_error "Failed to install 'hugo' site builder. Missing 'go' compiler: '$MYCELIO_GOEXE'"
        return 2
    fi

    if [ -f "$MYCELIO_GOEXE" ]; then
        mkdir -p "$_hugo_tmp"
        rm -rf "$_hugo_tmp"
        run_task "hugo.git.clone" git -c advice.detachedHead=false clone -b "v0.100.0" "https://github.com/gohugoio/hugo.git" "$_hugo_tmp"

        if (
            cd "$_hugo_tmp"

            GOHOSTOS="$MYCELIO_OS"
            export GOHOSTOS

            GOARCH="$MYCELIO_ARCH"
            export GOARCH

            GOARM="$MYCELIO_ARM"
            export GOARM

            GOHOSTARCH="$MYCELIO_ARCH"
            export GOHOSTARCH

            # Note that CGO_ENABLED allows the creation of Go packages that call C code. There
            # is no support for GCC on Synology so not able to build extended features.
            if uname -a | grep -q "synology"; then
                CGO_ENABLED="0" run_task "hugo.build" "$MYCELIO_GOEXE" build -v -ldflags "-extldflags -static" -o "$_hugo_exe"
            else
                # https://github.com/gohugoio/hugo/blob/master/goreleaser.yml
                CGO_ENABLED="1" run_task "hugo.build" "$MYCELIO_GOEXE" build -v -tags extended -o "$_hugo_exe"
            fi
        ); then
            echo "✔ Successfully installed 'hugo' site builder."
        else
            log_error "Failed to install 'hugo' site builder."
        fi
    fi

    if [ ! -f "$_hugo_exe" ] || ! "$_hugo_exe" version; then
        log_error "Failed to install 'hugo' static site builder."
        return 3
    fi

    return 0
}

function install_oh_my_posh {
    if [ ! -f "$MYCELIO_HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
        _posh_themes="$MYCELIO_HOME/.poshthemes"
        mkdir -p "$_posh_themes"
        run_task "posh.themes.get" get_file "$_posh_themes/themes.zip" "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"

        if [ -x "$(command -v unzip)" ]; then
            run_task "posh.themes.unzip" unzip -o "$_posh_themes/themes.zip" -d "$_posh_themes"
        elif [ -x "$(command -v 7z)" ]; then
            run_task "posh.themes.7z" 7z e "$_posh_themes/themes.zip" -o"$_posh_themes" -r
        else
            echo "Neither 'unzip' nor '7z' commands available to extract oh-my-posh themes."
        fi

        chmod u+rw ~/.poshthemes/*.json
        rm -f "$_posh_themes/themes.zip"
    fi

    font_base_name="JetBrains Mono"
    font_base_filename=${font_base_name// /}
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$font_base_filename.zip"
    _fonts_path="$MYCELIO_HOME/.fonts"

    if [ ! -f "$_fonts_path/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
        mkdir -p "$_fonts_path"
        run_task "font.jetbrains.get" get_file "$_fonts_path/$font_base_filename.zip" "$font_url"

        if [ -x "$(command -v unzip)" ]; then
            run_task "fonts.unzip" unzip -o "$_fonts_path/$font_base_filename.zip" -d "$_fonts_path"
        elif [ -x "$(command -v 7z)" ]; then
            run_task "fonts.7z" 7z e "$_fonts_path/$font_base_filename.zip" -o"$_fonts_path" -r
        else
            echo "Neither 'unzip' nor '7z' commands available to extract fonts."
        fi

        chmod u+rw "$MYCELIO_HOME/.fonts"
        rm -f "$_fonts_path/$font_base_filename.zip"

        if [ -x "$(command -v fc-cache)" ]; then
            if fc-cache -fv >/dev/null 2>&1; then
                echo "✔ Flushed font cache."
            else
                echo "⚠ Failed to flush font cache."
            fi
        else
            echo "⚠ Unable to flush font cache as 'fc-cache' is not installed"
        fi
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped install of 'oh-my-posh' for root user."
        return 0
    fi

    _oh_my_posh_tmp="$MYCELIO_TEMP/oh_my_posh"
    _oh_my_posh_exe="$MYCELIO_GOBIN/oh-my-posh${MYCELIO_OS_APP_EXTENSION:-}"

    if [ -f "$MYCELIO_HOME/.local/bin/oh-my-posh" ]; then
        rm "$MYCELIO_HOME/.local/bin/oh-my-posh"
        echo "✔ Removed 'oh-my-posh' executable old location."
    fi

    if [ -f "$_oh_my_posh_exe" ]; then
        if [ ! "${MYCELIO_ARG_CLEAN:-}" = "1" ] && _version=$("$_oh_my_posh_exe" --version 2>&1) && [ "$_version" = "8.32.4" ]; then
            echo "✔ 'oh-my-posh' v$_version already installed."
            return 0
        else
            rm -rf "$_oh_my_posh_tmp"
            rm -f "$_oh_my_posh_exe"
            echo "Removed oh-my-posh binary: '$_oh_my_posh_exe'"
        fi
    fi

    _posh_archive="posh-$MYCELIO_OS-$MYCELIO_ARCH$MYCELIO_OS_APP_EXTENSION"
    _posh_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/$_posh_archive"
    if run_task "posh.get" get_file "$_oh_my_posh_exe" "$_posh_url"; then
        chmod +x "$_oh_my_posh_exe"
    fi

    if ! _version=$("$_oh_my_posh_exe" --version 2>&1); then
        if [ ! -x "$(command -v git)" ]; then
            log_error "Failed to install 'oh-my-posh' extension. Required 'git' tool missing."
            return 1
        fi

        if [ ! -f "$MYCELIO_GOEXE" ]; then
            log_error "Failed to install 'oh-my-posh' extension. Missing 'go' compiler: '$MYCELIO_GOEXE'"
            return 2
        fi

        if [ -f "$MYCELIO_GOEXE" ]; then
            mkdir -p "$_oh_my_posh_tmp"
            rm -rf "$_oh_my_posh_tmp"
            run_task "oh-my-posh.git.clone" git -c advice.detachedHead=false clone -b "v7.26.0" "https://github.com/JanDeDobbeleer/oh-my-posh.git" "$_oh_my_posh_tmp"

            if (
                cd "$_oh_my_posh_tmp/src"

                GOHOSTOS="$MYCELIO_OS"
                export GOHOSTOS

                GOARCH="$MYCELIO_ARCH"
                export GOARCH

                GOARM="$MYCELIO_ARM"
                export GOARM

                GOHOSTARCH="$MYCELIO_ARCH"
                export GOHOSTARCH

                # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/.github/workflows/release.yml
                run_task "oh-my-posh.build" "$MYCELIO_GOEXE" build -a -ldflags "-extldflags -static" -o "$_oh_my_posh_exe"
            ); then
                echo "Successfully installed 'oh-my-posh' site builder."
            else
                echo "Failed to install 'oh-my-posh' site builder."
            fi
        fi
    fi

    if ! _version=$("$_oh_my_posh_exe" --version 2>&1); then
        log_error "Failed to install 'oh-my-posh' terminal helper."
        return 3
    fi

    echo "✔ Installed 'oh-my-posh' v$_version."

    return 0
}

function install_fzf {
    _local_root="$MYCELIO_HOME/.local"
    _fzf_root="$_local_root/fzf"
    _fzf_exe="$_local_root/bin/fzf${MYCELIO_OS_APP_EXTENSION:-}"

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_fzf_root"
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'fzf' install for root user."
        return 0
    fi

    if [ -d "$_fzf_root" ] && [ -f "$_fzf_exe" ]; then
        echo "✔ 'fzf' already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Required 'git' tool missing."
        return 0
    fi

    if [ ! -f "$MYCELIO_GOEXE" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Missing 'go' compiler: '$MYCELIO_GOEXE'"
        return 0
    fi

    if [ ! -x "$(command -v make)" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Required 'make' tool missing."
        return 0
    fi

    mkdir -p "$_fzf_root"
    rm -rf "$_fzf_root"
    run_task "fzf.git.clone" git -c advice.detachedHead=false clone -b "0.27.2" "https://github.com/junegunn/fzf.git" "$_fzf_root"

    if (
        cd "$_fzf_root"
        run_task "fzf.build" "$MYCELIO_GOEXE" build -a -ldflags "-s -w" -o "$_fzf_exe"
    ); then
        echo "✔ Successfully generated 'fzf' utility with 'go' compiler."
    else
        log_error "Failed to install 'fzf' utility."
    fi

    if [ ! -f "$_fzf_exe" ]; then
        log_error "Failed to compile 'fzf' utility."
        return 3
    fi

    echo "fzf v$("$_fzf_exe" --version)"

    return 0
}

function install_powershell() {
    if [ -x "$(command -v apt-get)" ]; then
        if [ -f "/etc/os-release" ]; then
            # shellcheck disable=SC1091
            source "/etc/os-release"
        fi

        if [ "${ID:-}" = "ubuntu" ]; then
            _packages_production="packages-microsoft-prod.deb"
            _url="https://packages.microsoft.com/config/ubuntu/${VERSION_ID:-0.0}/$_packages_production"

            # Download the Microsoft repository GPG keys
            if run_task "powershell.key.get" get_file "$MYCELIO_TEMP/$_packages_production" "$_url"; then
                # Register the Microsoft repository GPG keys
                run_command_sudo "dpkg.register.microsoft" dpkg -i "$MYCELIO_TEMP/$_packages_production"

                # Update the list of products
                run_command_sudo "apt.update" apt-get update

                # Enable the "universe" repositories
                run_command_sudo "apt.add.repository" add-apt-repository --yes universe || true

                # Install PowerShell
                if
                    DEBIAN_FRONTEND="noninteractive" run_command_sudo "apt.install.powershell" \
                        apt-get install -y --no-install-recommends powershell
                then
                    echo "Installed PowerShell."
                else
                    echo "WARNING: Failed to install PowerShell."
                fi
            fi
        fi
    else
        echo "Skipped PowerShell install "
    fi
}

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#
function install_stow() {
    MYCELIO_PERL="${MYCELIO_PERL:-$(command -v perl)}"
    export MYCELIO_PERL

    _cpan_temp_bin="$MYCELIO_TEMP/cpanm"

    if [ "${MSYSTEM:-}" = "MINGW64" ]; then
        _cpan_root="$MYCELIO_HOME/.cpan-w64"
        _cpanm_root="$MYCELIO_HOME/.cpanm-w64"
    else
        _cpan_root="$MYCELIO_HOME/.cpan"
        _cpanm_root="$MYCELIO_HOME/.cpanm"
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -f "$_cpan_temp_bin" >/dev/null 2>&1

        rm -f "$MYCELIO_HOME/.local/bin/cpanm" >/dev/null 2>&1

        rm -rf "$_cpan_root" >/dev/null 2>&1
        rm -rf "$_cpanm_root" >/dev/null 2>&1

        rm -f "$MYCELIO_STOW_ROOT/bin/stow" >/dev/null 2>&1
        rm -f "$MYCELIO_STOW_ROOT/bin/chkstow" >/dev/null 2>&1
    fi

    if [ ! -f "$MYCELIO_STOW_ROOT/configure.ac" ]; then
        log_error "'stow' source missing: '$MYCELIO_STOW_ROOT'"
        return 20
    elif (
        if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
            # shellcheck source=source/stow/tools/make-clean.sh
            run_task "stow.make.clean" source "$MYCELIO_STOW_ROOT/tools/make-clean.sh"
        fi

        # shellcheck source=source/stow/tools/make-stow.sh
        run_task "stow.make" source "$MYCELIO_STOW_ROOT/tools/make-stow.sh"
    ); then
        echo "✔ Successfully built 'stow' from source."
    else
        log_error "Failed to build 'stow' from source."
        return 15
    fi

    # Remove intermediate Perl files in case another version of Perl generated
    # some files that are incompatible with current version.
    rm -rf "$MYCELIO_ROOT/_Inline"
    rm -rf "$MYCELIO_STOW_ROOT/_Inline"

    _stow --version
}

function install_micro_text_editor() {
    mkdir -p "$MYCELIO_HOME/.local/bin/"
    _micro_exe="micro$MYCELIO_OS_APP_EXTENSION"

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -f "$MYCELIO_HOME/.local/bin/$_micro_exe"
    fi

    # Install micro text editor. It is optional so ignore failures
    if [ -f "$MYCELIO_HOME/.local/bin/$_micro_exe" ]; then
        echo "✔ micro text editor already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ] || [ ! -x "$(command -v make)" ]; then
        echo "Skipped 'micro' compile. Missing build tools."
    else
        _tmp_micro="$MYCELIO_TEMP/micro"
        mkdir -p "$_tmp_micro"
        rm -rf "$_tmp_micro"
        run_task "micro.git.clone" git -c advice.detachedHead=false clone -b "v2.0.10" "https://github.com/zyedidia/micro" "$_tmp_micro"

        if (
            cd "$_tmp_micro"
            run_task "micro.make" make build
        ); then
            if [ -f "$_tmp_micro/$_micro_exe" ]; then
                rm -f "$MYCELIO_HOME/.local/bin/$_micro_exe"
                mv "$_tmp_micro/$_micro_exe" "$MYCELIO_HOME/.local/bin/"
            fi

            echo "✔ Successfully compiled micro text editor."
        fi
    fi

    if [ ! -f "$MYCELIO_HOME/.local/bin/$_micro_exe" ]; then
        if (
            mkdir -p "$MYCELIO_HOME/.local/bin/"
            cd "$MYCELIO_HOME/.local/bin/"
            install_micro="$MYCELIO_HOME/.local/bin/micro_install.sh"
            run_task "micro.get" get_file "$install_micro" "https://getmic.ro"
            chmod a+x "$install_micro"
            run_task "micro.install" "$install_micro"
        ); then
            echo "[mycelio] Successfully installed 'micro' text editor."
        else
            echo "[mycelio] WARNING: Failed to install 'micro' text editor."
            return 2
        fi
    fi

    return 0
}

function install_go {
    _local_root="$MYCELIO_HOME/.local"
    _local_go_root="$_local_root/go"
    _local_go_bootstrap_root="$_local_root/gobootstrap"
    _go_bootstrap_exe="$_local_go_bootstrap_root/bin/go"
    _go_requires_update=0
    _go_required_version_minor=18

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'go' install for root user."
        return 0
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_local_go_root"
        rm -rf "$_local_go_bootstrap_root"
    fi

    export MYCELIO_GOROOT="${MYCELIO_GOROOT:-$HOME/.local/go}"
    export MYCELIO_GOBIN="${MYCELIO_GOBIN:-$MYCELIO_GOROOT/bin}"
    export MYCELIO_GOEXE="${MYCELIO_GOEXE:-$MYCELIO_GOBIN/go${MYCELIO_OS_APP_EXTENSION:-}}"

    if [ -f "$MYCELIO_GOEXE" ] && _go_version="$("$MYCELIO_GOEXE" version 2>&1 | (
        read -r _ _ v _
        echo "${v#go}"
    ))"; then
        _go_version_minor=$(echo "$_go_version" | cut -d. -f2)
        if [ "$_go_version_minor" -lt "$_go_required_version_minor" ]; then
            _go_requires_update=1
        fi
    else
        _go_requires_update=1
    fi

    if [ "${MSYSTEM:-}" = "MSYS" ]; then
        _go_os="linux"
    else
        _go_os="$MYCELIO_OS"
    fi

    if [ "$_go_requires_update" = "1" ]; then
        _go_version="1.$_go_required_version_minor"
        _go_compiled=0

        if [ ! -x "$(command -v gcc)" ] && [ ! -x "$(command -v make)" ]; then
            log_error "Skipped 'go' compile. Missing GCC toolchain."
        else
            if [ "${MSYSTEM:-}" = "MSYS" ]; then
                # https://golang.org/doc/install/source
                _go_bootstrap_archive="$MYCELIO_TEMP/go1.4.windows-amd64.zip"
                run_task "go.bootstrap.get" get_file "$_go_bootstrap_archive" "https://golang.org/dl/go1.4.windows-amd64.zip"
                echo "Extracting 'go' binaries: '$_go_bootstrap_archive'"
                rm -rf "$MYCELIO_TEMP/go" || true
                run_task "go.bootstrap.tar" tar -C "$MYCELIO_TEMP" -xzf "$_go_bootstrap_archive"
                rm -rf "$_local_go_bootstrap_root" || true
                mv "$MYCELIO_TEMP/go" "$_local_go_bootstrap_root"
                rm "$_go_bootstrap_src_archive"

                if [ -f "$_go_bootstrap_exe" ]; then
                    echo "✔ Using pre-built 'go' compiler for MSYS environment."
                else
                    if [ -f "/mingw64/bin/go" ]; then
                        _go_bootstrap_exe="/mingw64/bin/go"
                        _local_go_bootstrap_root=$($_go_bootstrap_exe env GOROOT)
                    else
                        log_error "Missing required 'go' compiler for MSYS environment."
                    fi
                fi
            elif [ ! -f "$_go_bootstrap_exe" ]; then
                # https://golang.org/doc/install/source
                _go_bootstrap_src_archive="$MYCELIO_TEMP/go_bootstrap.tgz"
                run_task "go.bootstrap.get" get_file "$_go_bootstrap_src_archive" "https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz"
                rm -rf "$MYCELIO_TEMP/go" || true
                run_task "go.bootstrap.tar" tar -C "$MYCELIO_TEMP" -xzf "$_go_bootstrap_src_archive"
                rm -rf "$_local_go_bootstrap_root" || true
                mv "$MYCELIO_TEMP/go" "$_local_go_bootstrap_root"
                rm "$_go_bootstrap_src_archive"

                if (
                    GOROOT_FINAL="$_local_go_bootstrap_root"
                    export GOROOT_FINAL

                    GOOS="$_go_os"
                    export GOOS

                    GOHOSTOS="$_go_os"
                    export GOHOSTOS

                    GOARCH="$MYCELIO_ARCH"
                    export GOARCH

                    GOARM="$MYCELIO_ARM"
                    export GOARM

                    GOHOSTARCH="$MYCELIO_ARCH"
                    export GOHOSTARCH

                    # shellcheck disable=SC2031
                    export CGO_ENABLED=0
                    cd "$_local_go_bootstrap_root/src"

                    if [ -x "$(command -v cygpath)" ]; then
                        if [ "${MSYSTEM:-}" = "MSYS" ]; then
                            export GO_LDFLAGS="--subsystem,console"
                        fi

                        run_task "go.bootstrap.make" cmd "\/d" "\/c" "$_local_go_bootstrap_root/src/make.bat"
                    else
                        run_task "go.bootstrap.make" ./make.bash
                    fi

                    unset GOROOT_FINAL
                ); then
                    echo "Compiled 'go' bootstrap from source: '$_local_go_bootstrap_root/src'"
                else
                    log_error "Failed to compile 'go' bootstrap from source."
                fi
            fi

            # https://golang.org/doc/install/source
            if [ -f "$_go_bootstrap_exe" ]; then
                _go_src_archive="$MYCELIO_TEMP/go.tgz"
                run_task "go.get" get_file "$_go_src_archive" "https://dl.google.com/go/go$_go_version.src.tar.gz"

                run_task "go.source.extract" tar -C "$_local_root" -xzf "$_go_src_archive"
                rm "$_go_src_archive"

                if (
                    cd "$_local_go_root/src"

                    GOROOT_BOOTSTRAP="$($_go_bootstrap_exe env GOROOT)"
                    export GOROOT_BOOTSTRAP

                    GOOS="$_go_os"
                    export GOOS

                    GOHOSTOS="$_go_os"
                    export GOHOSTOS

                    GOARCH="$MYCELIO_ARCH"
                    export GOARCH

                    GOARM="$MYCELIO_ARM"
                    export GOARM

                    GOHOSTARCH="$MYCELIO_ARCH"
                    export GOHOSTARCH

                    if [ -x "$(command -v cygpath)" ]; then
                        run_task "go.make" cmd "\/d" "\/c" "$_local_go_root/src/make.bat"
                    else
                        run_task "go.make" ./make.bash
                    fi

                    if [ ! -f "$MYCELIO_GOEXE" ]; then
                        exit 2
                    fi

                    # Pre-compile the standard library, just like the official binary release tarballs do
                    run_command "go.install.std" "$MYCELIO_GOEXE" install std
                ); then
                    echo "✔ Compiled 'go' from source.: '$_local_go_root/src'"
                    _go_compiled=1
                else
                    echo "⚠ Failed to compile 'go' from source."
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
                *)
                    _go_archive=""
                    ;;
                esac
            fi

            # Install Golang
            if [ -z "${_go_archive:-}" ]; then
                echo "⚠ Unsupported platform for installing 'go' language."
            else
                echo "Downloading archive: 'https://dl.google.com/go/$_go_archive'"
                run_task "go.source.get" get_file "$MYCELIO_TEMP/$_go_archive" "https://dl.google.com/go/$_go_archive"
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
                        log_error "Failed to update 'go' install."
                    fi

                    rm -rf "$_go_tmp"
                    echo "Removed temporary 'go' files: '$_go_tmp'"
                fi
            fi
        fi
    fi

    if [ -f "$MYCELIO_GOEXE" ] && _go_version=$("$MYCELIO_GOEXE" version); then
        # The net package requires cgo by default because the host operating system
        # must in general mediate network call setup. On some systems, though, it is
        # possible to use the network without cgo, and useful to do so, for instance
        # to avoid dynamic linking. The new build tag netgo (off by default) allows
        # the construction of a net package in pure Go on those systems where it is possible.
        #   "$MYCELIO_GOEXE" build -tags netgo -a -v

        echo "✔ $_go_version"
    else
        log_error "Failed to install 'go' language."
        return 5
    fi

    return 0
}

function install_macos_apps() {
    if ! [ -x "$(command -v brew)" ]; then
        run_task "brew.install.get" get_file "$MYCELIO_TEMP/brew_install.sh" "https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
        chmod a+x "$MYCELIO_TEMP/brew_install.sh"
        run_task "brew.install" "$MYCELIO_TEMP/brew_install.sh"
    fi

    brew upgrade

    if ! run_task "brew.bundle" brew bundle --file="$MYCELIO_ROOT/source/macos/Brewfile"; then
        log_error "Install with 'brew' failed with errors, but continuing."
    fi

    run_task "cask.upgrade" cask upgrade

    #
    # We install these seprately as they can fail if already installed.
    #
    if [ ! -d "/Applications/Google Chrome.app" ]; then
        run_task "cask.google.chrome" brew install --cask "google-chrome" || true
    fi

    # https://github.com/JetBrains/JetBrainsMono
    if [ ! -f "/Users/$(whoami)/Library/Fonts/JetBrainsMono-BoldItalic.ttf" ]; then
        run_task "cask.font.jetbrains" brew install --cask "font-jetbrains-mono" || true
    fi

    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        run_task "cask.vscode" brew install --cask "visual-studio-code" || true
    fi

    # If user is not signed into the Apple store, notify them and skip install
    if ! mas account >/dev/null; then
        echo "Skipped app store installs. Please open App Store and sign in using your Apple ID."
    else
        # Powerful keep-awake utility, see https://apps.apple.com/us/app/amphetamine/id937984704
        # 'Amphetamine', id: 937984704
        run_task "mas.install.amphetamine" mas install 937984704 || true
    fi

    echo "Installed dependencies with 'brew' package manager."
}

function generate_gnugp_config() {
    _gnupg_config_root="$1"

    if mkdir -p "$_gnupg_config_root" &>/dev/null; then
        _gnupg_templates_root="$MYCELIO_ROOT/source/gnupg"

        cp -f "$_gnupg_templates_root/gpg-agent.template.conf" "$_gnupg_config_root/gpg-agent.conf"
        if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
            _pin_entry="$(_get_windows_root)/Program Files (x86)/GnuPG/bin/pinentry-basic.exe"
        elif [ -f "/usr/local/bin/pinentry-mac" ]; then
            _pin_entry="/usr/local/bin/pinentry-mac"
        fi

        if [ -f "${_pin_entry:-}" ]; then
            # Must use double quotes and not single quotes here or it fails
            echo "pinentry-program \"$_pin_entry\"" | tee -a "$_gnupg_config_root/gpg-agent.conf"
        elif [ -n "${_pin_entry:-}" ]; then
            log_error "Failed to find pinentry program: '$_pin_entry'"
        fi
        echo "Created config from template: '$_gnupg_config_root/gpg-agent.conf'"

        cp -f "$_gnupg_templates_root/gpg.template.conf" "$_gnupg_config_root/gpg.conf"
        echo "Created config from template: '$_gnupg_config_root/gpg.conf'"

        # Set permissions for GnuGP otherwise we can get permission errors during use. We
        # intentionally set permissions differently for files and directories.
        find "$_gnupg_config_root" -type f -exec chmod 600 {} \;
        find "$_gnupg_config_root" -type d -exec chmod 700 {} \;
    fi
}

function configure_linux() {
    if [ "$MYCELIO_ARG_CLEAN" = "1" ] || [ "$MYCELIO_ARG_FORCE" = "1" ]; then
        task_group "Stow: Sterilize Target" _stow_packages --delete
    fi

    mkdir -p "$MYCELIO_HOME/.config/fish/functions"

    (
        # Not all platforms support '--relative' so go into target directory first
        cd "$MYCELIO_HOME/.config/fish/functions" || true

        # Link fzf (https://github.com/junegunn/fzf) key bindings after we have tried to install it. We intentionally
        # want to create this before we stow packages since we want to make sure the parent folder is not a symbolic
        # link which would cause problems if running a Docker image on this folder if a symbolic link exists inside it.
        _binding_file="../../../.local/fzf/shell/key-bindings.fish"

        _binding_link="fzf_key_bindings.fish"
        if [ -e "$_binding_file" ]; then
            rm -f "$_binding_link"
            ln -s "$_binding_file" "$_binding_link"
        fi
    )

    (
        # Not all platforms support '--relative' so go into target directory first. Ideally we
        # could just submit this link but on Windows, the symlink needs to be valid when created
        # and since 'base16-irblack.sh' is in a submodule, it is not synced/created until after
        # the repository (including that link) would be created.
        cd "$MYCELIO_ROOT/packages/fish" || true
        rm -f "$MYCELIO_HOME/.base16_theme"
        rm -f ".base16_theme"
        ln -s ".config/base16-shell/scripts/base16-irblack.sh" ".base16_theme"
    )

    _fundle_fish="$MYCELIO_HOME/.config/fish/functions/fundle.fish"
    if [ ! -f "$_fundle_fish" ]; then
        mkdir -p "$MYCELIO_HOME/.config/fish/functions"
        run_task "fundle.get" get_file "$_fundle_fish" "https://git.io/fundle" || true

        if [ -f "$_fundle_fish" ]; then
            chmod a+x "$_fundle_fish"
        fi
    fi

    # Stow packages after we have installed fundle and setup custom links
    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        task_group "Stow: Regenerate Mycelium" _stow_packages --restow
    else
        task_group "Stow: Inoculate Mycelium" _stow_packages
    fi

    if [ -x "$(command -v fish)" ]; then
        if [ ! -f "$_fundle_fish" ]; then
            log_error "Fundle not installed in home directory: '$MYCELIO_HOME/.config/fish/functions/fundle.fish'"
        else
            if run_task "Install Fundle" fish -c "fundle install"; then
                echo "✔ Installed 'fundle' package manager for fish."
            else
                log_error "Failed to install 'fundle' package manager for fish."
            fi
        fi
    else
        echo "⚠ Skipped fish shell initialization as it is not installed."
    fi

    if [ -x "$(command -v apt-get)" ] && [ -x "$(command -v sudo)" ]; then
        DEBIAN_FRONTEND="noninteractive" run_task_sudo "Remove Intermediate Package Data" \
            apt-get autoremove -y
    fi

    # Remove intermediate files here to reduce size of Docker container layer
    if [ -f "/.dockerenv" ] && [ "$MYCELIO_ARG_CLEAN" = "1" ]; then
        rm -rf "$MYCELIO_TEMP" || true
        sudo rm -rf "/tmp/*" || true
        sudo rm -rf "/usr/tmp/*" || true
        sudo rm -rf "/var/lib/apt/lists/*" || true
        echo "Removed intermediate temporary fails from Docker instance."
    fi

    # Left-over sometimes created by 'micro' text editor
    rm -f "$MYCELIO_ROOT/log.txt" || true

    # Remove intermediate Perl files
    rm -rf "$MYCELIO_ROOT/_Inline"

    return 0
}

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

function install_python() {
    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped Python setup for root user."
    elif [ -x "$(command -v python3)" ] && _python_version=$(python3 --version); then
        echo "$_python_version"

        if ! python3 -m pip --version >/dev/null 2>&1; then
            run_task "pip.get" get_file "$MYCELIO_TEMP/get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
            chmod a+x "$MYCELIO_TEMP/get-pip.py"
            run_task "pip.install" python3 "$MYCELIO_TEMP/get-pip.py"
        fi

        run_command "python.pip.upgrade" python3 -m pip install --user --upgrade pip

        # Could install with 'snapd' but there are issues with 'snapd' on WSL so to maintain
        # consistency between platforms and not install hacks we just use 'pip3' instead. For
        # details on the issue, see https://github.com/microsoft/WSL/issues/5126
        run_command "python.pip.precommit" python3 -m pip install --user pre-commit

        echo "✔ Upgraded 'pip3' and installed 'pre-commit' package."
    else
        log_error "Missing or invalid Python 3 install: $(command -v python3)"
    fi
}

function initialize_linux() {
    dotenv="$MYCELIO_HOME/.env"
    if [ ! -f "$dotenv" ]; then
        echo "# Generated by Mycelio dotfiles project." >"$dotenv"
        echo "" >>"$dotenv"
    fi

    if ! grep -q "MYCELIO_ROOT=$MYCELIO_ROOT" "$dotenv"; then
        echo "MYCELIO_ROOT=$MYCELIO_ROOT" >>"$dotenv"
        echo "Added 'MYCELIO_ROOT' to dotenv file: '$dotenv'"
    fi

    task_group "Install Packages" install_packages
    task_group "Install Python" install_python

    if [ ! -d "$MYCELIO_HOME/.asdf" ]; then
        if [ -x "$(command -v git)" ]; then
            run_task "asdf.git.clone" git -c advice.detachedHead=false clone "https://github.com/asdf-vm/asdf.git" "$MYCELIO_HOME/.asdf" --branch "v0.8.1"
        else
            echo "Skipped 'asdf' install. Missing required 'git' tool."
        fi
    fi

    install_stow

    install_go
    install_oh_my_posh
    install_hugo
    install_fzf
    install_powershell
    install_micro_text_editor
}

function initialize_macos() {
    install_macos_apps

    # We need to do this after we install macOS apps as it installs some
    # dependencies needed for this step.
    initialize_linux

    # Disabled temporarily while settings are still in flux
    # run_task 'configure.dock' configure_macos_dock
    # run_task 'configure.finder' configure_macos_finder
    # run_task 'configure.apps' configure_macos_apps
    # run_task 'configure.system' configure_macos_system
}

function configure_macos_apps() {
    for f in source/macos/*.plist; do
        [ -e "$f" ] || continue

        echo "Importing settings: $f"
        plist=$(basename -s .plist "$f")
        defaults delete "$plist" >/dev/null || true
        defaults import "$plist" "$f"
    done

    echo "✔ Configured macOS applications with settings"
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

    echo "✔ Configured 'Dock'"
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

    echo "✔ Configured 'Finder'"
}

function _remove_trailing_slash() {
    echo "$1" | sed 's/\/*$//g'
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
    MYCELIO_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"
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
        trap '__trap_error "$LINENO" ${BASH_LINENO[@]+"${BASH_LINENO[@]}"}' ERR

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

    _load_profile

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
    *)
        # No action needed
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

function _update_git_repository() {
    _path="$1"
    _branch="$2"
    _remote="${3:-}"
    _name=$(basename "$_path")

    if [ -n "${_remote:-}" ]; then
        run_command "$_name.git.remote" git -C "$MYCELIO_ROOT/$_path" remote set-url "origin" "$_remote"
    fi

    run_command "$_name.git.fetch" git -C "$MYCELIO_ROOT/$_path" fetch

    if ! git -C "$MYCELIO_ROOT/$_path" symbolic-ref -q HEAD >/dev/null 2>&1; then
        run_command "$_name.git.checkout" git -C "$MYCELIO_ROOT/$_path" checkout "$_branch"
    fi

    run_command "$_name.git.pull" git -C "$MYCELIO_ROOT/$_path" pull "origin" "$_branch" --rebase --autostash
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

function update_repositories() {
    if [ -x "$(command -v git)" ] && [ -e "$MYCELIO_ROOT/.git" ]; then
        if [ ! -f "$MYCELIO_ROOT/source/stow/setup.sh" ]; then
            run_command "git.submodule.update" git submodule update --init --recursive || true
        fi

        # _update_git_repository "source/stow" "main" "https://github.com/joelvaneenwyk/stow"
        # _update_git_repository "packages/vim/.vim/bundle/vundle" "master"
        # _update_git_repository "packages/macos/Library/Application Support/Resources" "master"
        # _update_git_repository "packages/fish/.config/base16-shell" "master"
        # _update_git_repository "packages/fish/.config/base16-fzf" "master"
        # _update_git_repository "packages/fish/.config/git-fuzzy" "master"
        # _update_git_repository "test/bats" "master"
        # _update_git_repository "test/test_helper/bats-support" "master"
        # _update_git_repository "test/test_helper/bats-assert" "master"

        echo "[mycelio] Updated submodules."
    fi
}

function _initialize_environment() {
    _parse_arguments "$@"

    # Need to setup environment variables before anything else
    _setup_environment

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

    if ! _load_profile; then
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

function is_synology() {
    if uname -a | grep -q "synology"; then
        return 0
    fi

    return 1
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
