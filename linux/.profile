#!/usr/bin/env sh
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
#
# See /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
#

#
# USAGE: _unique_list [list]
#
#   list - a colon delimited list.
#
# RETURNS: 'list' with duplicated directories removed
#
_unique_list() {
    _arg_input_list="${1:-}"
    _list=':'

    # Wrap the while loop in '{}' to be able to access the updated _list variable
    # as the while loop is run in a subshell due to the piping to it.
    # https://stackoverflow.com/questions/4667509/shell-variables-set-inside-while-loop-not-visible-outside-of-it
    printf '%s\n' "$_arg_input_list" | tr -s ':' '\n' | {
        while read -r dir; do
            _list_left="${_list%:"$dir":*}" # remove last occurrence to end
            if [ "$_list" = "$_list_left" ]; then
                # PATH doesn't contain $dir
                _list="$_list$dir:"
            fi
        done
        # strip ':' pads
        _list="${_list#:}"
        _list="${_list%:}"
        # return
        printf '%s\n' "$_list"
    }
}

_add_to_list() {
    _list="$(_unique_list "${1-}")"
    _list=":$1:"
    shift

    case "$1" in
    'include' | 'prepend' | 'append')
        _action="$1"
        shift
        ;;
    *) _action='include' ;;
    esac

    for dir in "$@"; do
        # Remove last occurrence to end
        _list_left="${_list%:"$dir":*}"

        if [ "$_list" = "$_list_left" ]; then
            # PATH doesn't contain $dir
            [ "$_action" = 'include' ] && _action='append'
            _list_right=''
        else
            # Remove start to last occurrence
            _list_right=":${_list#"$_list_left":"$dir":}"
        fi

        # Construct _list with $dir added
        case "$_action" in
        'prepend') _list=":$dir$_list_left$_list_right" ;;
        'append') _list="$_list_left$_list_right$dir:" ;;
        esac
    done

    # Strip ':' pads
    _list="${_list#:}"
    _list="${_list%:}"

    # Return combined path
    printf '%s' "$_list"
}

#
# USAGE: addPath [include|prepend|append] "dir1" "dir2" ...
#
#   prepend: add/move to beginning
#   append:  add/move to end
#   include: add to end of PATH if not already included [default]
#          that is, don't change position if already in PATH
#
# RETURNS:
#   prepend:  dir2:dir1:OLD_PATH
#   append:   OLD_PATH:dir1:dir2
#
# If called with no paramters, returns PATH with duplicate directories removed
#
_add_path() {
    PATH="$(_add_to_list "$PATH" "$@")"
    export PATH
}

_initialize_interactive_profile() {
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
        if [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
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

    if ! _parent="$(ps -o args= $PPID)"; then
        _parent="UNKNOWN"
    fi

    machine="UNKNOWN"
    variant="$(uname -s)"

    case "${variant:-}" in
    Linux*)
        if uname -a | grep -q "synology"; then
            machine=Synology
        else
            machine=Linux
        fi

        if grep -qEi "(Microsoft|WSL)" /proc/version >/dev/null 2>&1; then
            variant=WSL
        else
            variant=$(uname -mrs)
        fi
        ;;
    Darwin*)
        machine=macOS
        ;;
    CYGWIN*)
        machine=Windows
        variant=Cygwin
        ;;
    MINGW*)
        machine=Windows
        variant=MINGW
        ;;
    MSYS*)
        machine=Windows
        variant=MSYS
        ;;
    esac

    echo "▓▓░░"
    echo "▓▓░░   ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
    echo "▓▓░░   ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
    echo "▓▓░░   ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
    echo "▓▓░░"
    echo "▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≡≡≡"
    echo ""
    echo "Initialized '${machine}:${variant}' environment: '$MYCELIO_ROOT'"
    echo ""
    echo "Parent: $_parent"
    echo ""
    echo "  gpgtest     Validate that git commit signing will work with secret key"
    echo "  refresh     Try to pull latest 'dotfiles' and reload profile"
    echo "  micro       Default text editor. Press 'F2' to save and 'F4' to exit."
    echo ""
}

_start_tmux() {
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

_initialize_go_paths() {
    _go_root="$HOME/.local/bin/go"
    _go_bin="$_go_root/bin/go"

    export GOROOT="$_go_root"
    export GOBIN="$_go_root/bin"

    _add_path "prepend" "$GOBIN"

    if [ -f "$_go_bin" ]; then
        unset GOPATH
        "$_go_bin" env -w GOROOT="$GOROOT"
        "$_go_bin" env -w GOBIN="$GOROOT/bin"
    fi
}

_initialize_windows() {
    if [ -d "${MYCELIO_ROOT:-}" ]; then
        export STOW_ROOT=$MYCELIO_ROOT/source/stow
        export PERL5LIB=$PERL5LIB:$STOW_ROOT/lib

        _add_path "prepend" "$STOW_ROOT/bin"
        _add_path "prepend" "$MYCELIO_ROOT/.tmp/texlive/bin/win32"

        alias stow='perl -I "$STOW_ROOT/lib" "$STOW_ROOT/bin/stow"'
    fi
}

_initialize_synology() {
    #This fixes the backspace when telnetting in.
    #if [ "$TERM" != "linux" ]; then
    #        stty erase
    #fi

    if [ "$(whoami)" = "root" ]; then
        HOME=/root
        export HOME

        USERNAME=root
        export USERNAME
    fi
}

_initialize_profile() {
    export EDITOR="micro"
    export PAGER="less -r"
    export LC_ALL="C"
    export LC_COLLATE="C"

    GPG_TTY=$(tty)
    export GPG_TTY

    _add_path "prepend" "/usr/local/gnupg/bin"
    _add_path "prepend" "$HOME/.local/bin"
    _add_path "prepend" "$HOME/.local/sbin"
    _add_path "prepend" "$HOME/.config/git-fuzzy/bin"
    _add_path "prepend" "/mnt/c/Program Files/Microsoft VS Code/bin"

    if uname -a | grep -q "synology"; then
        _initialize_synology
    fi

    _initialize_go_paths

    case "$(uname -s)" in
    CYGWIN*)
        _initialize_windows
        ;;
    MINGW*)
        _initialize_windows
        ;;
    MSYS*)
        _initialize_windows
        ;;
    esac

    # If not running interactively, don't do anything else.
    case $- in
    *i*) ;;
    *)
        return
        ;;
    esac

    _initialize_interactive_profile
}

_initialize_profile "$@"
