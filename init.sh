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

function initialize_linux() {
    sudo apt-get update
    DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y git stow sudo micro neofetch
    DEBIAN_FRONTEND="noninteractive" sudo apt-get autoremove -y

    stow bash
    stow vim

    initialize_gitconfig

    # Install the secure key-server certificate (Ubuntu/Debian)
    mkdir -p /usr/local/share/ca-certificates/
    curl -s https://sks-keyservers.net/sks-keyservers.netCA.pem | sudo tee /usr/local/share/ca-certificates/sks-keyservers.netCA.crt
    sudo update-ca-certificates

    neofetch
}

function initialize_windows() {
    _dot_script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    _dot_initialized="$_dot_script_root/.tmp/.initialized"

    if [ "$1" == "clean" ]; then
        rm -rf "${_dot_script_root}/.tmp"
        echo "Removed workspace temporary files to force a rebuild."
    fi

    # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
    if [ -x "$(command -v pacman)" ] && [ ! -f "$_dot_initialized" ]; then
        rm -f /var/lib/pacman/db.lck
        pacman -Syu --noconfirm
        pacman -S --noconfirm --needed msys2-keyring curl unzip

        if [ -f /etc/pacman.d/gnupg/ ]; then
            rm -r /etc/pacman.d/gnupg/
        fi

        pacman-key --init
        pacman-key --populate msys2

        # Long version of '-Syuu' gets fresh package databases from server and
        # upgrades the packages while allowing downgrades '-uu' as well if needed.
        pacman --sync --refresh -uu --noconfirm
    fi

    mkdir --parents "$_dot_script_root/.tmp/"

    if [ ! -x "$(command -v micro)" ]; then
        (cd "$_dot_script_root/.tmp/" && curl "https://getmic.ro" | bash)
    fi

    source "$_dot_script_root/windows/build-stow.sh"

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

    if ! brew bundle; then
        echo "Install with 'brew' failed with errors, but continuing."
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
