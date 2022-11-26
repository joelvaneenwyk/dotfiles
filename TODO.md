# TODO

Remove all submodules and inline everything we need perhaps using `git subtree` or something similar.

One of the ideas behind this project was to use `bash`/`sh` more as a replacement for either `cmd` or `powershell` so that less has to be installed to get up and running. This felt like a decent concept but in the end, it is too difficult to manage `bash` scripts at scale.

On top of that, submodules are just a nightmare. They work and mostly fine but can be annoying to work with:

1. Submodules may not work if your git is not setup correctly e.g., does not have the correct `core.autocrlf` setting.
2. The existence of submodules results in certain views in VSCode becoming cluttered with repositories we do not actually care to look at. They will even come back again after you "close" them in VSCode.

## Stow

`git subtree add --prefix source/stow https://github.com/joelvaneenwyk/stow.git main --squash`

## Reference

```ini
[submodule "source/stow"]
  path = source/stow
  url = https://github.com/joelvaneenwyk/stow
  branch = main

[submodule "vundle"]
  path = packages/vim/.vim/bundle/vundle
  url = https://github.com/VundleVim/Vundle.vim
  branch = master

[submodule "mailmate"]
  path = packages/macos/Library/Application Support/Resources
  url = https://github.com/chauncey-garrett/mailmate.git
  update = rebase
  branch = master

[submodule "base16-shell"]
  path = packages/fish/.config/base16-shell
  url = https://github.com/chriskempson/base16-shell.git
  branch = master

[submodule "base16-fzf"]
  path = packages/fish/.config/base16-fzf
  url = https://github.com/nicodebo/base16-fzf.git
  branch = master

[submodule "git-fuzzy"]
  path = packages/fish/.config/git-fuzzy
  url = https://github.com/bigH/git-fuzzy.git
  branch = master

[submodule "bats-core"]
  path = test/bats
  url = https://github.com/bats-core/bats-core.git
  branch = master

[submodule "bats-support"]
  path = test/test_helper/bats-support
  url = https://github.com/bats-core/bats-support.git
  branch = master

[submodule "bats-assert"]
  path = test/test_helper/bats-assert
  url = https://github.com/bats-core/bats-assert.git
  branch = master
```
