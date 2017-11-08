# install plugins
if not functions -q fundle; eval (curl -sfL https://git.io/fundle-install); end

fundle plugin 'edc/bass'
fundle plugin 'fisherman/getopts'
fundle plugin 'fisherman/fzf'
fundle plugin 'fisherman/z'
fundle init

# suppress fish greeting
set -x fish_greeting ""

# update path
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/anaconda/bin $PATH

# color stderr in red
set -gx LD_PRELOAD "$HOME/.local/lib/libstderred.so"

# use java 1.8 by default
set -gx JAVA_HOME (/usr/libexec/java_home -v 1.8)

# aliases
alias more="less -r"
alias less="less -r"
alias ll="ls -lh"
alias grep="grep --color=always"
alias pr="hub -c core.commentChar='%' pull-request"

# use hub if available
if test (which hub) != ""
    alias git="hub"
end

# set editor
set -gx EDITOR /usr/bin/vim

# set color scheme
if status --is-interactive
    source $HOME/.config/base16-shell/profile_helper.fish
end

bass source ~/.config/base16-fzf/build_scheme/(basename (readlink $HOME/.base16_theme) .sh).config
set -x FZF_DEFAULT_OPTS (echo $FZF_DEFAULT_OPTS | tr -d '\n')

# enable activating anaconda environments
if test (which conda) != ""
    source (conda info --root)/etc/fish/conf.d/conda.fish
end

