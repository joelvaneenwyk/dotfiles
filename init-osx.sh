#!/usr/bin/env bash
#
# Usage: ./init-osx.sh
#
# - Install commonly used apps using "brew bundle" (see Brewfile).
# - Uses "stow" to link config files into home directory.
# - Sets some app settings (derived from https://github.com/Sajjadhosn/dotfiles).

set -e

main() {
   install_apps

   configure_dock
   configure_finder
   configure_apps
   configure_system
}

function install_apps() {
   if ! [ -x "$(command -v brew)" ]; then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   fi

   brew bundle

   pip3 install neovim-remote
}

function configure_apps() {
   stow bash
   stow fish
   stow fonts
   stow osx
   stow vim

   defaults delete com.if.Amphetamine >/dev/null || true
   defaults import com.if.Amphetamine .osx/amphetamine.plist

   defaults delete com.googlecode.iterm2 >/dev/null || true
   defaults import com.googlecode.iterm2 .osx/iterm2.plist
}

function configure_dock() {
   quit "Dock"

   # Set the icon size of Dock items to 36 pixels
   defaults write com.apple.dock tilesize -int 36
   # Wipe all (default) app icons from the Dock
   defaults write com.apple.dock persistent-apps -array
   # Show only open applications in the Dock
   defaults write com.apple.dock static-only -bool true
   # Don’t animate opening applications from the Dock
   defaults write com.apple.dock launchanim -bool false
   # Disable Dashboard
   defaults write com.apple.dashboard mcx-disabled -bool true
   # Don’t show Dashboard as a Space
   defaults write com.apple.dock dashboard-in-overlay -bool true
   # Automatically hide and show the Dock
   defaults write com.apple.dock autohide -bool true
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

   open "Dock"
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
}

function configure_system() {
   # Disable Gatekeeper entirely to get rid of "Are you sure you want to open this application?" dialog
   echo "Type password to disable Gatekeeper questions (are you sure you want to open this application?)"
   sudo spctl --master-disable
}

function quit() {
   app=$1
   killall "$app" > /dev/null 2>&1
}

function open() {
   app=$1
   osascript << EOM
tell application "$app" to activate
EOM
}

main "$@"

