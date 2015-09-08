# suppress fish greeting
set -x fish_greeting ""

# color stderr in red
set -x LD_PRELOAD "$HOME/.local/lib/libstderred.so"

# aliases
alias more="less -r"
alias less="less -r"
alias ll="ls -lh --color=always"
alias grep="grep --color=always"

# use hub if available
if test (which hub) != ""
    alias git="hub"
end

# use z
. $HOME/.config/fish/z.fish

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

