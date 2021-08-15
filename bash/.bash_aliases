#!/usr/bin/env bash

alias pgptest='echo "test" | gpg --clearsign --homedir "$HOME/.gnupg"'
alias gpgtest='echo "test" | gpg --clearsign --homedir "$HOME/.gnupg"'

alias refresh='git -C "$DOTFILE_CONFIG_ROOT/../" pull || source "$DOTFILE_CONFIG_ROOT/.bashrc"'

alias less='less -r'
alias more='less -r'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

unameOut="$(uname -s)"

case "${unameOut}" in
Darwin*)
    alias dir='dir -G'
    alias vdir='vdir -G'

    alias grep='grep -G'
    alias fgrep='fgrep -G'
    alias egrep='egrep -G'

    alias ll='ls -alF -G'
    alias ls='ls -alF -G'
    alias la='ls -A -G'
    alias l='ls -CF -G'
    ;;
*)
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    alias ll='ls -alF --color=always'
    alias ls='ls -alF --color=always'
    alias la='ls -A --color=always'
    alias l='ls -CF --color=always'
    ;;
esac
