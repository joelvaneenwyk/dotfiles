#!/usr/bin/env bash
#
# Usage: ./init.sh
#
# - Install commonly used apps using "brew bundle" (see Brewfile).
# - Uses "stow" to link config files into home directory.
# - Sets some app settings (derived from https://github.com/Sajjadhosn/dotfiles).

set -e

main() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
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
    *) machine="UNKNOWN:${unameOut}" ;;
    esac

    echo "Initialized '${machine}' machine."
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
    if [ ! -x "$(command -v hugo)" ] && [ -x "$(command -v git)" ] && [ -f "/usr/local/go/bin/go" ]; then
        rm -rf "/tmp/hugo"
        git -c advice.detachedHead=false clone -b "v0.87.0" "https://github.com/gohugoio/hugo.git" "/tmp/hugo"
        cd "/tmp/hugo" && sudo /usr/local/go/bin/go install --tags extended
    fi

    if [ -x "$(command -v hugo)" ]; then
        hugo version
    else
        echo "Failed to install 'hugo' static site builder."
    fi
}

function install_go {
    if [ -x "$(command -v go)" ]; then
        version=$(go version | {
            read -r _ _ v _
            echo "${v#go}"
        })
        minor=$(echo "$version" | cut -d. -f2)
    fi

    if [ ! -x "$(command -v go)" ] || ((minor < 16)); then
        # Install Golang
        if [ ! -f "/tmp/go1.16.7.linux-amd64.tar.gz" ]; then
            wget https://dl.google.com/go/go1.16.7.linux-amd64.tar.gz --directory-prefix=/tmp/
        fi

        sudo rm -rf "/tmp/go"
        sudo tar -xvf "/tmp/go1.16.7.linux-amd64.tar.gz" --directory "/tmp/"
        sudo rm -rf "/usr/local/go"
        sudo mv "/tmp/go" "/usr/local"
        echo "Updated 'go' install: '/usr/local/go'"
    fi

    if [ -x "$(command -v go)" ]; then
        go version
    else
        echo "Failed to install 'go' language."
    fi
}

function initialize_linux() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    sudo apt-get update

    DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y \
        sudo git wget curl unzip xclip \
        software-properties-common build-essential gcc g++ make \
        stow micro tmux neofetch fish \
        python3 python3-pip

    DEBIAN_FRONTEND="noninteractive" sudo apt-get autoremove -y

    if [ -x "$(command -v pip3)" ]; then
        pip3 install --upgrade pip

        # Could install with 'snapd' but there are issues with 'snapd' on WSL so to maintain
        # consistency between platforms and not install hacks we just use 'pip3' instead. For
        # details on the issue, see https://github.com/microsoft/WSL/issues/5126
        pip3 install pre-commit
    fi

    if [ ! -x "$(command -v oh-my-posh)" ]; then
        sudo wget "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64" -O "/usr/local/bin/oh-my-posh"
        sudo chmod +x "/usr/local/bin/oh-my-posh"
    fi

    if [ ! -d "$HOME/.poshthemes" ]; then
        mkdir -p "$HOME/.poshthemes"
        wget "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" -O "$HOME/.poshthemes/themes.zip"
        unzip -o "$HOME/.poshthemes/themes.zip" -d "$HOME/.poshthemes"
        sudo chmod u+rw ~/.poshthemes/*.json
        rm -f "$HOME/.poshthemes/themes.zip"
    fi

    install_go
    install_hugo

    stow bash "$@"
    stow vim "$@"

    initialize_gitconfig

    # Install the secure key-server certificate (Ubuntu/Debian)
    mkdir -p /usr/local/share/ca-certificates/
    curl -s https://sks-keyservers.net/sks-keyservers.netCA.pem | sudo tee /usr/local/share/ca-certificates/sks-keyservers.netCA.crt
    sudo update-ca-certificates

    _gpg_agent_config="$HOME/.gnupg/gpg-agent.conf"
    rm -f "$_gpg_agent_config"
    unlink "$_gpg_agent_config" >/dev/null 2>&1 || true
    mkdir -p "$HOME/.gnupg"
    touch "$_gpg_agent_config"
    echo "default-cache-ttl 34560000" >>"$_gpg_agent_config"
    echo "max-cache-ttl 34560000" >>"$_gpg_agent_config"
    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        echo "pinentry-program \"/mnt/c/Program Files (x86)/GnuPG/bin/pinentry-basic.exe\"" >>"$_gpg_agent_config"
    fi
    echo "Created custom gpg agent configuration: '$_gpg_agent_config'"

    neofetch
}

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#
function build_stow() {
    _dot_windows_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    echo "[stow] Script directory: '$_dot_windows_script_root'"

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
        cd "$_dot_windows_script_root/stow" || true
        autoreconf --install --verbose 2>&1 | awk '{ print "[stow.autoreconf]", $0 }'

        # We want a local install
        ./configure --prefix="" 2>&1 | awk '{ print "[stow.configure]", $0 }'

        # Documentation part is expected to fail but we can ignore that
        make --keep-going --ignore-errors 2>&1 | awk '{ print "[stow.make]", $0 }'

        rm -f "./configure~"
        git checkout -- "./aclocal.m4" || true
    ) || true
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

            if [ -f /etc/pacman.d/gnupg/ ]; then
                rm -r /etc/pacman.d/gnupg/
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

    install_apps

    configure_dock
    configure_finder
    configure_apps
    configure_system
}

function install_apps() {
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

function configure_apps() {
    mkdir -p ~/.config/fish
    mkdir -p ~/.ssh
    mkdir -p ~/Library/Application\ Support/Code

    stow bash
    stow fish
    stow fonts
    stow macos
    stow ruby
    stow vim
    stow zsh

    # We use built-in VSCode syncing so disabled the stow operation
    #stow vscode

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

function configure_dock() {
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

function configure_finder() {
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
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    echo "Configured Finder."
}

function configure_system() {
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

main "$@"
