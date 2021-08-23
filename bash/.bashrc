#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
function _get_real_path() {
    _pwd="$(pwd)"
    _input_path="$1"

    cd "$(dirname "$_input_path")" || true

    _link=$(readlink "$(basename "$_input_path")")
    while [ "$_link" ]; do
        cd "$(dirname "$_link")" || true
        _link=$(readlink "$(basename "$_input_path")")
    done

    _real_path="$(pwd)/$(basename "$_input_path")"
    cd "$_pwd" || true

    echo "$_real_path"
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

function _initialize_synology() {
    if [ "$(whoami)" == "root" ]; then
        # Only for console (ssh/telnet works w/o resize)
        # shellcheck disable=SC2009
        isTTY=$(ps | grep $$ | grep tty)

        # Only for bash (bash needs to resize and can support these commands)
        # shellcheck disable=SC2116
        isBash=$(echo "${BASH_VERSION:-}")

        # Only for interactive (not necessary for "su -")
        isInteractive=$(echo $- | grep i)

        if [ -n "$isTTY" ] && [ -n "$isBash" ] && [ -n "$isInteractive" ]; then
            shopt -s checkwinsize

            # shellcheck disable=SC2016
            checksize='echo -en "\E7 \E[r \E[999;999H \E[6n"; read -sdR CURPOS;CURPOS=${CURPOS#*[}; IFS="?; \t\n"; read lines columns <<< "$(echo $CURPOS)"; unset IFS'

            # shellcheck disable=SC2086
            eval $checksize

            # Columns is 1 in Procomm ANSI-BBS
            # shellcheck disable=SC2154
            if [ 1 != "$columns" ]; then
                # shellcheck disable=SC2016
                export_stty='export COLUMNS=$columns; export LINES=$lines; stty columns $columns; stty rows $lines'

                # shellcheck disable=SC2139
                alias resize="$checksize; columns=\$((\$columns - 1)); $export_stty"

                # shellcheck disable=SC2004
                eval "$checksize; columns=$(($columns - 1)); $export_stty"

                # shellcheck disable=SC2142
                alias vim='function _vim(){ eval resize; TERM=xterm vi $@; }; _vim'
            else
                # shellcheck disable=SC2142
                alias vim='TERM=xterm vi $@'
            fi

            alias vi='vim'
            alias ps='COLUMNS=1024 ps'
        fi
    fi
}

function _initialize_interactive_bash_profile() {
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

    # Alias definitions.
    # You may want to put all your additions into a separate file like
    # ~/.bash_aliases, instead of adding them here directly.
    # See /usr/share/doc/bash-doc/examples in the bash-doc package.
    if [ -f "$HOME/.bash_aliases" ]; then
        # shellcheck source=bash/.bash_aliases
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

    if [ -x "$(command -v asdf)" ]; then
        if [ -x "$(command -v brew)" ]; then
            # shellcheck disable=SC1091
            source "$(brew --prefix asdf)/asdf.sh"
        elif [ -f "$HOME/.asdf/asdf.sh" ]; then
            # shellcheck disable=SC1091
            . "$HOME/.asdf/asdf.sh"

            if [ -f "$HOME/.asdf/completions/asdf.bash" ]; then
                # shellcheck disable=SC1091
                . "$HOME/.asdf/completions/asdf.bash"
            fi
        fi
    fi

    if [ -x "$(command -v oh-my-posh)" ] && [ -f "$HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
        eval "$(oh-my-posh --init --shell bash --config "$HOME/.poshthemes/stelbent.minimal.omp.json")"
    fi
}

function _initialize_bash_profile() {
    # We alias 'grep' in '.profile' so initialize Synology first
    if uname -a | grep -q "synology"; then
        _initialize_synology
    fi

    # Generic POSIX shell profile setup. This will print the logo if
    # we are not running interactively.
    if [ -f "$HOME/.profile" ]; then
        # shellcheck source=linux/.profile
        . "$HOME/.profile" "$@"
    fi

    if [ -f "${MYCELIO_ROOT:-}/init.sh" ]; then
        MYCELIO_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
        export MYCELIO_ROOT
    fi

    #if ! _start_tmux; then
    #    export WORKSPACE_ROOT=/volume1/homes/jvaneenwyk/workspace
    #    . "${WORKSPACE_ROOT:-}/entrypoint"
    #fi

    # If not running interactively, don't do anything else.
    case $- in
    *i*) ;;
    *)
        return
        ;;
    esac

    _initialize_interactive_bash_profile
}

_initialize_bash_profile "$@"
