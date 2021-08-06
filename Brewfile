cask_args appdir: "/Applications"

tap "homebrew/cask-fonts"
tap "neovim/neovim"
tap "koekeishiya/formulae"

brew "asdf"
brew "exa"
brew "fd"
brew "fish"
brew "fzf"
brew "hub"
brew "koekeishiya/formulae/skhd"
brew "koekeishiya/formulae/yabai"
brew "neovim"
brew "ripgrep"
brew "stow"

cask "arq"
cask "dropbox"
cask "font-jetbrains-mono"
cask "fsnotes"
cask "google-chrome"
cask "hiddenbar"
cask "iterm2"
cask "macpass"
cask "mailmate"
cask "mylio"
cask "skype"
cask "typora"
cask "visual-studio-code"
cask "wire"

# If user is not signed into the Apple store, notify them and skip install
if ! mas account >/dev/null; then
    echo "Skipped app store installs. Please open App Store and sign in using your Apple ID."
else
    # Powerful keep-awake utility, see https://apps.apple.com/us/app/amphetamine/id937984704
    mas 'Amphetamine', id: 937984704
fi
