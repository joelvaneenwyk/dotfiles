#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

GPG_TTY=$(tty)
export GPG_TTY

DOTFILE_CONFIG_ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export DOTFILE_CONFIG_ROOT

function _path_prepend() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:${PATH:+":$PATH"}"
    fi
}

function _start_tmux() {
    if ! { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; }; then
        tmux new-session -d -s mycelio -n mycowin
        tmux send-keys -t mycelio:mycowin "cd ~/workspace" Enter
        tmux source-file ~/.tmux.conf
        tmux attach -t mycelio:mycowin
        setw -g mouse on
        tmux
        return 0
    fi

    return 1
}

function _initialize_go_paths() {
    _go_root="$HOME/.local/bin/go"
    _go_bin="$_go_root/bin/go"

    export GOROOT="$_go_root"
    export GOBIN="$GOROOT/bin"

    _path_prepend "$GOBIN"

    if [ -f "$_go_bin" ]; then
        GOPATH="$("$_go_bin" env GOPATH)"
        export GOPATH

        "$_go_bin" env -w GOROOT="$GOROOT"
        "$_go_bin" env -w GOBIN="$GOROOT/bin"
    fi
}

function _initialize_windows() {
    export STOW_ROOT=$DOTFILE_CONFIG_ROOT/../stow
    export PERL5LIB=$PERL5LIB:$DOTFILE_CONFIG_ROOT/../stow/lib

    _path_prepend "$DOTFILE_CONFIG_ROOT/../stow/bin"
    _path_prepend "$DOTFILE_CONFIG_ROOT/../.tmp/texlive/bin/win32"

    alias stow='perl -I "$STOW_ROOT/lib" "$STOW_ROOT/bin/stow"'
}

function _initialize_synology() {
    #This fixes the backspace when telnetting in.
    #if [ "$TERM" != "linux" ]; then
    #        stty erase
    #fi

    if [ "$(whoami)" == "root" ]; then
        HOME=/root
        export HOME

        # Only for console (ssh/telnet works w/o resize)
        isTTY=$(ps | grep $$ | grep tty)

        # Only for bash (bash needs to resize and can support these commands)
        isBash=$(echo $BASH_VERSION)

        # Only for interactive (not necessary for "su -")
        isInteractive=$(echo $- | grep i)

        if [ -n "$isTTY" -a -n "$isBash" -a -n "$isInteractive" ]; then
            shopt -s checkwinsize

            checksize='echo -en "\E7 \E[r \E[999;999H \E[6n"; read -sdR CURPOS;CURPOS=${CURPOS#*[}; IFS="?; \t\n"; read lines columns <<< "$(echo $CURPOS)"; unset IFS'

            eval $checksize

            # columns is 1 in Procomm ANSI-BBS
            if [ 1 != "$columns" ]; then
                export_stty='export COLUMNS=$columns; export LINES=$lines; stty columns $columns; stty rows $lines'
                alias resize="$checksize; columns=\$((\$columns - 1)); $export_stty"
                eval "$checksize; columns=$(($columns - 1)); $export_stty"

                alias vim='function _vim(){ eval resize; TERM=xterm vi $@; }; _vim'
            else
                alias vim='TERM=xterm vi $@'
            fi

            alias vi='vim'
            alias ps='COLUMNS=1024 ps'
        fi
    fi
}

function _initialize() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
    Linux*)
        if uname -a | grep -q "synology"; then
            machine=Synology
        else
            machine=Linux
        fi

        if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
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
        variant=${unameOut}
        ;;
    esac

    _initialize_go_paths

    if uname -a | grep -q "synology"; then
        _initialize_synology
    fi

    #if ! _start_tmux; then
    #    export WORKSPACE_ROOT=/volume1/homes/jvaneenwyk/workspace
    #    . "${WORKSPACE_ROOT:-}/entrypoint"
    #fi

    # Add paths that may already exist but we can't be guaranteed that '.profile' is sourced so we
    # do this here again just in case.
    _path_prepend "$HOME/.local/bin"
    _path_prepend "$HOME/.local/sbin"
    _path_prepend "$HOME/.config/git-fuzzy/bin"
    _path_prepend "/mnt/c/Program Files/Microsoft VS Code/bin"
    _path_prepend "/usr/local/gnupg/bin"
}

_initialize

# If not running interactively, don't do anything else.
case $- in
*i*) ;;
*)
    return
    ;;
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

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f "$HOME/.bash_aliases" ]; then
    source "$HOME/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        # shellcheck disable=SC1091
        source "/usr/share/bash-completion/bash_completion"
    elif [ -f /etc/bash_completion ]; then
        # shellcheck disable=SC1091
        source "/etc/bash_completion"
    fi
fi

# shellcheck disable=SC1091
if [ -f "$HOME/.fzf.bash" ]; then
    source "$HOME/.fzf.bash"
fi

# shellcheck disable=SC1091
if [ -x "$(command -v asdf)" ]; then
    source "$(brew --prefix asdf)/asdf.sh"
fi

if [ -x "$(command -v oh-my-posh)" ]; then
    eval "$(oh-my-posh --init --shell bash --config ~/.poshthemes/stelbent.minimal.omp.json)"
fi

_parent="$(ps -o args= $PPID)"

echo "▓▓░░"
echo "▓▓░░   ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
echo "▓▓░░   ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
echo "▓▓░░   ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
echo "▓▓░░"
echo "▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≡≡≡"
echo ""
echo "Initialized '${machine}:${variant}' environment: '$DOTFILE_CONFIG_ROOT'"
echo ""
echo "Parent: $_parent"
echo ""
echo "  gpgtest     Validate that git commit signing will work with secret key"
echo "  refresh     Try to pull latest 'dotfiles' and reload profile"
echo "  micro       Default text editor. Press 'F2' to save and 'F4' to exit."
echo ""
