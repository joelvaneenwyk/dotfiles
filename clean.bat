@echo off

rmdir /q /s "%~dp0source/stow"
rmdir /q /s "%~dp0packages/vim/.vim/bundle/vundle"
rmdir /q /s "%~dp0packages/macos/Library/Application Support/Resources"
rmdir /q /s "%~dp0packages/fish/.config/base16-shell"
rmdir /q /s "%~dp0packages/fish/.config/base16-fzf"
rmdir /q /s "%~dp0packages/fish/.config/git-fuzzy"
rmdir /q /s "%~dp0test/bats"
rmdir /q /s "%~dp0test/test_helper/bats-support"
rmdir /q /s "%~dp0test/test_helper/bats-assert"
