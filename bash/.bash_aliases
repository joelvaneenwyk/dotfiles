#!/usr/bin/env bash

alias gpgreset='gpg-connect-agent updatestartuptty /bye'
alias pgptest='source "$MYCELIO_ROOT/source/shell/pgptest.sh"'
alias gpgtest='source "$MYCELIO_ROOT/source/shell/pgptest.sh"'
alias cls='clear'

## Common typos
alias cd..='cd ..'
alias cd~='cd ~'

## Faster way to move around
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

alias refresh='git -C "$MYCELIO_ROOT" pull || source "$MYCELIO_ROOT/bash/.bashrc"'

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
