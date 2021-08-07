#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

export GPG_TTY=$(tty)
export DOTFILE_CONFIG_ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

function _initialize_windows() {
    export STOW_ROOT=$DOTFILE_CONFIG_ROOT/../stow
    export PERL5LIB=$PERL5LIB:$DOTFILE_CONFIG_ROOT/../stow/lib
    export PATH=$DOTFILE_CONFIG_ROOT/../stow/bin:$DOTFILE_CONFIG_ROOT/../.tmp/texlive/bin/win32:$PATH
    alias stow='perl -I "$STOW_ROOT/lib" "$STOW_ROOT/bin/stow"'
}

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*)
    machine=Linux

    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
        variant=WSL
    else
        variant=$(uname -mrs)
    fi
    ;;
Darwin*)
    machine=macOS
    variant=$unameOut
    ;;
CYGWIN*)
    machine=Windows
    variant=Cygwin
    _initialize_windows
    ;;
MINGW*)
    machine=Windows
    variant=MINGW
    _initialize_windows
    ;;
MSYS*)
    machine=Windows
    variant=MSYS
    _initialize_windows
    ;;
*)
    machine="UNKNOWN"
    variant=${unameOut};;
esac

# If not running interactively, don't do anything else.
case $- in
*i*) ;;
*) return ;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*) ;;
esac

# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        # shellcheck disable=SC1091
        . "/usr/share/bash-completion/bash_completion"
    elif [ -f /etc/bash_completion ]; then
        # shellcheck disable=SC1091
        . "/etc/bash_completion"
    fi
fi

# shellcheck disable=SC1091
[ -f "$HOME/.fzf.bash" ] && source "$HOME/.fzf.bash"

# shellcheck disable=SC1091
[ -x "$(command -v asdf)" ] && source "$(brew --prefix asdf)/asdf.sh"

echo "▓▓░░"
echo "▓▓░░   ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
echo "▓▓░░   ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
echo "▓▓░░   ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
echo "▓▓░░"
echo "▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≡≡≡"
echo ""
echo "Initialized '${machine}:${variant}' environment: '$DOTFILE_CONFIG_ROOT'"
echo ""
echo "Commands:"
echo ""
echo "  gpgtest     Validate that git commit signing will work with secret key"
echo "  refresh     Try to pull latest 'dotfiles' and reload profile"
echo "  micro       Default text editor. Press 'F2' to save and 'F4' to exit."
