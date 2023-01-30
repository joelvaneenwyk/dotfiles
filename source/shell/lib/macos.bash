#!/bin/bash

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
