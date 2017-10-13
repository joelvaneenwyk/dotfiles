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

bass source ~/.config/base16-fzf/build_scheme/base16-ir-black.config
set -x FZF_DEFAULT_OPTS (echo $FZF_DEFAULT_OPTS | tr -d '\n')

# enable activating anaconda environments
source (conda info --root)/etc/fish/conf.d/conda.fish

function bash
    set -lx NOFISH 1
    /bin/bash $argv
end

function haste
    set bin (which haste)
    eval $bin > /tmp/haste.url
    if test $status = 0
        set url (cat /tmp/haste.url)
        echo $url | xclip -selection primary
        echo $url | xclip -selection clipboard
        xdg-open $url
    end

    rm -f /tmp/haste.url
end

