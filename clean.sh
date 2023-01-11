#!/bin/sh

git fetch --all
git branch "backups/main"
git reset --hard origin/main
rm -rf \
    ./packages/fish/.config/base16-fzf \
    ./packages/fish/.config/base16-shell \
    ./packages/fish/.config/git-fuzzy \
    ./packages/macos/Library/Application Support/Resources \
    ./packages/vim/.vim/bundle/vundle \
    ./source/stow \
    ./test/bats \
    ./test/test_helper/bats-assert \
    ./test/test_helper/bats-support
git reset --hard origin/main
git clean -xfd
