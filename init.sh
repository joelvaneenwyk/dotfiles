#!/usr/bin/env bash
#
# Usage: ./init.sh
#
#   - Install commonly used apps using "brew bundle" (see Brewfile) or apt-get (on Ubunutu/Debian).
#   - Uses "stow" to link config files into home directory.
#   - Sets some app settings which were derived from https://github.com/Sajjadhosn/dotfiles
#

set -o errexit
set -o errtrace
set -T
shopt -s extdebug

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

function initialize_gitconfig() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    _gitConfig="$HOME/.gitconfig"

    rm -f "$_gitConfig"
    unlink "$_gitConfig" >/dev/null 2>&1 || true
    echo "[include]" >"$_gitConfig"
    echo "    path = $_dot_script_root/git/.gitconfig_common" >>"$_gitConfig"
    echo "    path = $_dot_script_root/git/.gitconfig_linux" >>"$_gitConfig"

    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        echo "    path = $_dot_script_root/git/.gitconfig_wsl" >>"$_gitConfig"
        echo "Added WSL to '.gitconfig' include directives."
    fi

    echo "Created custom '.gitconfig' with include directives."
}

function install_hugo {
    _local_bin="$HOME/.local/bin"
    _go_root="$_local_bin/go"
    _go_bin="$_go_root/bin/go"
    _hugo_bin="$_go_root/bin/hugo"

    if [ ! -f "$_hugo_bin" ] && [ -x "$(command -v git)" ] && [ -f "$_go_bin" ]; then
        _tmp="$HOME/.tmp"
        _tmp_hugo="$_tmp/hugo"
        mkdir -p "$_tmp_hugo"

        rm -rf "$_tmp_hugo"
        git -c advice.detachedHead=false clone -b "v0.87.0" "https://github.com/gohugoio/hugo.git" "$_tmp_hugo"

        _go_env_root="$_go_root"
        _go_env_bin="$_go_env_root/bin"

        if (
            cd "$_tmp_hugo"

            # We only modify the environment for this subshell and that is the expectation
            # so we ignore the warnings here.
            # shellcheck disable=SC2030
            export GOROOT="$_go_env_root"
            # shellcheck disable=SC2030
            export GOBIN="$_go_env_bin"

            # No support for GCC on Synology so not able to build extended features
            if ! uname -a | grep -q "synology"; then
                export CGO_ENABLED="1"
                echo "##[cmd] $_go_bin install --tags extended"
                "$_go_bin" install --tags extended
            else
                export CGO_ENABLED="0"
                echo "##[cmd] $_go_bin install"
                "$_go_bin" install
            fi
        ); then
            echo "Successfully installed 'go' compiler."
        else
            echo "Failed to install 'go' compiler."
        fi
    fi

    if [ -f "$_hugo_bin" ]; then
        "$_hugo_bin" version
    else
        echo "Failed to install 'hugo' static site builder."
    fi
}

function install_go {
    _local_go_root="$HOME/.local/bin/go"
    _go_bin="$_local_go_root/bin/go"
    _go_requires_update=0

    if [ -f "$_go_bin" ] && _go_version="$("$_go_bin" version 2>&1 | (
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
        _arch_name="$(uname -m)"
        _go_arch=""

        if [ "${_arch_name}" = "x86_64" ]; then
            _go_arch="amd64"
        elif [ "${_arch_name}" = "x86" ]; then
            _go_arch="386"
        elif [ "${_arch_name}" = "arm64" ]; then
            _go_arch="arm64"
        fi

        if _uname_output="$(uname -s 2>/dev/null)"; then
            case "${_uname_output}" in
            Linux*)
                _go_archive="go$_go_version.linux-$_go_arch.tar.gz"
                ;;
            Darwin*)
                _go_archive="go$_go_version.darwin-$_go_arch.tar.gz"
                ;;
            esac
        fi

        # Install Golang
        if [ -z "$_go_archive" ]; then
            echo "Unsupported platform for installing 'go' language."
        else
            _tmp="$HOME/.tmp"
            mkdir -p "$_tmp/"
            echo "Downloading archive: 'https://dl.google.com/go/$_go_archive'"
            touch "$_tmp/$_go_archive"
            curl -o "$_tmp/$_go_archive" "https://dl.google.com/go/$_go_archive"
            echo "Downloaded archive: '$_go_archive'"

            _go_tmp="$_tmp/go"
            rm -rf "${_go_tmp:?}/"
            tar -xf "$_tmp/$_go_archive" --directory "$_tmp"
            echo "Extracted 'go' archive: '$_go_tmp'"

            mkdir -p "$_local_go_root/"
            rm -rf "${_local_go_root:?}/"
            cp -rf "$_go_tmp" "$_local_go_root"
            echo "Updated 'go' install: '$_local_go_root'"

            rm -rf "$_go_tmp"
            echo "Removed temporary 'go' files: '$_go_tmp'"
        fi
    fi

    if _version=$("$_go_bin" version); then
        echo "$_version"
    else
        echo "Failed to install 'go' language."
    fi
}

function _stow() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    if [ -x "$(command -v stow)" ]; then
        echo "##[cmd] stow --dir='$_dot_script_root' --target='$HOME' --verbose $*"
        stow --dir="$_dot_script_root" --target="$HOME" --verbose "$@"
    elif uname -a | grep -q "synology"; then
        _root_dir="$_dot_script_root/$1/"
        _root="$_dot_script_root/$1"

        find "$_root" -maxdepth 2 -type f -print0 | while IFS= read -r -d $'\0' file; do
            _offset="${file//$_root_dir/}"
            _source="$file"
            _target="$HOME/$_offset"
            if [ -f "$_source" ]; then
                rm -f "$_target"
                mkdir -p "$(dirname "$_target")"
                ln -s "$_source" "$_target"
                echo "Stowed '$1' target: '$_target'"
            fi
        done
    else
        echo "Unsupported 'stow' command. Skipped: 'stow $*'"
    fi
}

function initialize_linux() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    # Make sure we have the appropriate permissions to write to home temporary folder
    # otherwise much of this initialization will fail.
    _tmp="$HOME/.tmp"
    mkdir -p "$_tmp/"
    if ! touch "$_tmp/.test"; then
        echo "ERROR: Missing permissions to write to temp folder: '$_tmp'"
    else
        rm "$_tmp/.test"
    fi

    if uname -a | grep -q "synology"; then
        echo "Skipped installing dependencies. Not supported on Synology platform."
    elif [ -x "$(command -v apt)" ]; then
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
            software-properties-common build-essential gcc g++ make \
            stow micro tmux neofetch fish \
            python3 python3-pip \
            fontconfig

        if [ -x "$(command -v dpkg-reconfigure)" ]; then
            sudo dpkg-reconfigure --frontend noninteractive tzdata
        fi
    fi

    if [ "$(whoami)" == "root" ]; then
        echo "Skipping install of Python setup for root user."
    else
        if [ -x "$(command -v pip3)" ]; then
            pip3 install --user --upgrade pip

            # Could install with 'snapd' but there are issues with 'snapd' on WSL so to maintain
            # consistency between platforms and not install hacks we just use 'pip3' instead. For
            # details on the issue, see https://github.com/microsoft/WSL/issues/5126
            pip3 install --user pre-commit

            echo "Upgraded 'pip3' and installed 'pre-commit' package."
        fi
    fi

    if [ "$(whoami)" == "root" ]; then
        echo "Skipping install of 'oh-my-posh' for root user."
    else
        if [ ! -x "$(command -v oh-my-posh)" ]; then
            _local_bin="$HOME/.local/bin"
            mkdir -p "$_local_bin"
            wget "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" -O "$_local_bin/oh-my-posh"
            chmod +x "$_local_bin/oh-my-posh"
        fi

        font_base_name="JetBrains Mono"
        font_base_filename=${font_base_name// /}
        font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$font_base_filename.zip"
        _fonts_path="$HOME/.fonts"

        if [ ! -f "$_fonts_path/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
            mkdir -p "$_fonts_path"
            wget "$font_url" -O "$_fonts_path/$font_base_filename.zip"

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

        if [ ! -f "$HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
            _posh_themes="$HOME/.poshthemes"
            mkdir -p "$_posh_themes"
            wget "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -O "$_posh_themes/themes.zip"

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

    if [ ! -d "$HOME/.asdf" ]; then
        git -c advice.detachedHead=false clone "https://github.com/asdf-vm/asdf.git" "$HOME/.asdf" --branch v0.8.1
    fi

    if [ "$(whoami)" == "root" ]; then
        echo "Skipping install of 'go' and 'hugo' for root user."
    else
        install_go
        install_hugo
    fi

    _stow "$@" linux
    _stow "$@" bash
    _stow "$@" zsh
    _stow "$@" vim

    initialize_gitconfig

    # Install the secure key-server certificate (Ubuntu/Debian)
    if uname -a | grep -q "Ubuntu"; then
        mkdir -p /usr/local/share/ca-certificates/
        curl -s https://sks-keyservers.net/sks-keyservers.netCA.pem | sudo tee /usr/local/share/ca-certificates/sks-keyservers.netCA.crt
        sudo update-ca-certificates
    fi

    _gnupg_config_root="$HOME/.gnupg"
    _gnupg_templates_root="$_dot_script_root/templates/.gnupg"
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

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#
function build_stow() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    if [ -x "$(command -v stow)" ]; then
        echo "Command 'stow' already available. Skipping build."
    else
        echo "[stow] Script directory: '$_dot_script_root'"

        if [ -x "$(command -v cpan)" ]; then
            # Install '-i' but skip tests '-T' for the modules we need. We skip tests in part because
            # it is faster but also because tests in 'Test::Output' causes consistent hangs
            # in MSYS2, see https://rt-cpan.github.io/Public/Bug/Display/64319/
            cpan -i -T YAML Test::Output CPAN::DistnameInfo 2>&1 | awk '{ print "[stow.cpan]", $0 }'
        else
            echo "[stow] WARNING: Package manager 'cpan' not found. There will likely be missing perl dependencies."
        fi

        # Move to source directory and start install.
        (
            cd "$_dot_script_root/source/stow" || true
            autoreconf --install --verbose 2>&1 | awk '{ print "[stow.autoreconf]", $0 }'

            # We want a local install
            ./configure --prefix="" 2>&1 | awk '{ print "[stow.configure]", $0 }'

            # Documentation part is expected to fail but we can ignore that
            make --keep-going --ignore-errors 2>&1 | awk '{ print "[stow.make]", $0 }'

            rm -f "./configure~"
            git checkout -- "./aclocal.m4" || true
        ) || true
    fi
}

function initialize_windows() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    _dot_initialized="$_dot_script_root/.tmp/.initialized"

    if [ "$1" == "clean" ]; then
        rm -rf "${_dot_script_root}/.tmp"
        echo "[init.sh] Removed workspace temporary files to force a rebuild."
    fi

    # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
    if [ -x "$(command -v pacman)" ]; then
        if [ -f "$_dot_initialized" ]; then
            echo "[init.sh] Skipped package install. Already initialized."
        else
            # Primary driver for these dependencies is 'stow' but they are generally useful as well
            echo "[init.sh] Installing minimal packages to build dependencies on Windows using MSYS2."

            rm -f /var/lib/pacman/db.lck
            pacman -Syu --noconfirm
            pacman -S --noconfirm --needed msys2-keyring curl unzip make \
                perl autoconf automake1.16 automake-wrapper libtool \
                git gawk

            if [ -f "/etc/pacman.d/gnupg/" ]; then
                rm -rf "/etc/pacman.d/gnupg/"
            fi

            pacman-key --init
            pacman-key --populate msys2

            # Long version of '-Syuu' gets fresh package databases from server and
            # upgrades the packages while allowing downgrades '-uu' as well if needed.
            pacman --sync --refresh -uu --noconfirm
        fi
    else
        echo "[init.sh] WARNING: Package manager 'pacman' not found. There will likely be missing dependencies."
    fi

    # Install micro text editor. It is optional so ignore failures
    if [ ! -x "$(command -v micro)" ]; then
        if (cd "$_dot_script_root/.tmp/" && bash <(curl -s https://getmic.ro)); then
            echo "[init.sh] Successfully installed 'micro' text editor."
        else
            echo "[init.sh] WARNING: Failed to install 'micro' text editor."
        fi
    fi

    build_stow

    touch "$_dot_initialized"
}

function initialize_macos() {
    initialize_gitconfig

    install_macos_apps

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

    # The ones below are separate as they can fail if already installed.

    brew install --cask "google-chrome" || true

    # https://github.com/JetBrains/JetBrainsMono
    brew install --cask "font-jetbrains-mono" || true

    brew install --cask "visual-studio-code" || true

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
    mkdir -p ~/.config/fish
    mkdir -p ~/.ssh
    mkdir -p ~/Library/Application\ Support/Code

    _stow "$@" macos
    _stow "$@" linux

    _stow "$@" bash
    _stow "$@" zsh
    _stow "$@" fish

    _stow "$@" fonts
    _stow "$@" ruby
    _stow "$@" vim

    # We use built-in VSCode syncing so disabled the stow operation for VSCode
    # _stow vscode

    fish -c "./fish/.config/fish/config.fish || fundle install" || true

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
    defaults write com.apple.screencapture location -string "${HOME}/Downloads"
    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    # Set home directory as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
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
    echo "Type password to disable Gatekeeper questions (are you sure you want to open this application?)"
    sudo spctl --master-disable

    defaults write -g com.apple.mouse.scaling 3.0                              # mouse speed
    defaults write -g com.apple.trackpad.scaling 2                             # trackpad speed
    defaults write -g com.apple.trackpad.forceClick 1                          # tap to click
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 1 # three finger drag
    defaults write -g ApplePressAndHoldEnabled -bool false                     # repeat keys on hold

    echo "Configured system settings."
}

function _callstack() {
    callstack_end=${#FUNCNAME[@]}
    index=0

    local callstack=""
    while ((index < callstack_end)); do
        callstack+=$(printf '> %s:%d: %s()\\n' "${BASH_SOURCE[$index]}" "${BASH_LINENO[$index]}" "${FUNCNAME[$((index + 1))]}")
        ((++index))
    done

    echo "--------------------------------------" >&2
    printf "%b\n" "$callstack" >&2
}

function main() {
    trap '$(_callstack)' ERR

    MYCELIO_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
    export MYCELIO_ROOT

    _home=${HOME:-"$(cd "$MYCELIO_ROOT" && cd ../ && pwd)"}

    # We use 'whoami' as $USER is not set for scheduled tasks
    echo "User: '$(whoami)'"
    echo "User Home: '$_home'"
    echo "Dotfiles Root: '$MYCELIO_ROOT'"
    echo "=---------------------"

    # Reset in case getopts has been used previously in the shell.
    OPTIND=1
    while getopts "c" opt >/dev/null 2>&1; do
        case "$opt" in
        c)
            rm -f "$HOME/.profile"
            rm -f "$HOME/.bash_profile"
            rm -f "$HOME/.bashrc"
            echo "Removed existing profile data."
            ;;
        *)
            # We simply ignore invalid options
            ;;
        esac
    done
    shift $((OPTIND - 1))
    [ "${1:-}" = "--" ] && shift

    uname_system="$(uname -s)"
    case "${uname_system}" in
    Linux*)
        machine=Linux
        initialize_linux "$@"
        ;;
    Darwin*)
        machine=Mac
        initialize_macos "$@"
        ;;
    CYGWIN*)
        machine=Cygwin
        initialize_windows "$@"
        ;;
    MINGW*)
        machine=MinGw
        initialize_windows "$@"
        ;;
    MSYS*)
        machine=MSYS
        initialize_windows "$@"
        ;;
    *) machine="UNKNOWN:${uname_system}" ;;
    esac

    if [ -x "$(command -v apt)" ] && [ -x "$(command -v sudo)" ]; then
        DEBIAN_FRONTEND="noninteractive" sudo apt-get autoremove -y

        # Remove intermediate files here to reduce size of Docker container layer
        rm -rf "$HOME/.tmp" || true
        sudo rm -rf /var/lib/apt/lists/*

        if [ -f "/.dockerenv" ]; then
            sudo rm -rf "/tmp"
        fi
    fi

    echo "Initialized '${machine}' machine."

    if [ -f "$MYCELIO_ROOT/linux/.profile" ]; then
        # shellcheck source=linux/.profile
        . "$MYCELIO_ROOT/linux/.profile"
        echo "Refreshed profile data."
    fi

    if [ -x "$(command -v neofetch)" ]; then
        neofetch
    fi
}

main "$@"
