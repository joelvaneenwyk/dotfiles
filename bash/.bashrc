echo 'Loading ~/.bashrc'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ -x "$(command -v asdf)" ] && source $(brew --prefix asdf)/asdf.sh

