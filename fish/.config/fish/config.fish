# suppress fish greeting
set -x fish_greeting ""

# update path
set -gx PATH $HOME/.local/bin $HOME/.local/sbin $PATH
set -gx PATH $HOME/anaconda/bin $PATH

# color stderr in red
set -gx LD_PRELOAD "$HOME/.local/lib/libstderred.so"

# use java 1.7 by default
set -gx JAVA_HOME (/usr/libexec/java_home -v 1.7)

# aliases
alias more="less -r"
alias less="less -r"
alias ll="ls -lh"
alias grep="grep --color=always"

# use hub if available
if test (which hub) != ""
    alias git="hub"
end

# use z
. $HOME/.config/fish/z.fish

# set editor
set -gx EDITOR /usr/bin/vim

# load rbenv
if test (which rbenv) != ""
    status --is-interactive; and . (rbenv init -|psub)
end

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

