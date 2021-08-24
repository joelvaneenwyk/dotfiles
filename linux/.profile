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

    if ! _parent="$(ps -o args= ${PPID:-0} 2>&1 | head -n 1)"; then
        _parent="N/A"
    fi

    MYCELIO_OS_NAME="UNKNOWN"
    MYCELIO_OS_VARIANT="$(uname -s)"

    # We intentionally disable on some Windows variants due to corruption e.g. MSYS, Cygwin
    _use_oh_my_posh=1

    case "${MYCELIO_OS_VARIANT:-}" in
    Linux*)
        if uname -a | grep -q "synology"; then
            MYCELIO_OS_NAME=Synology
        else
            MYCELIO_OS_NAME=Linux
        fi

        if grep -qEi "(Microsoft|WSL)" /proc/version >/dev/null 2>&1; then
            MYCELIO_OS_VARIANT=WSL
        else
            MYCELIO_OS_VARIANT=$(uname -mrs)
        fi
        ;;
    Darwin*)
        MYCELIO_OS_NAME=macOS
        ;;
    CYGWIN*)
        MYCELIO_OS_NAME=Windows
        MYCELIO_OS_VARIANT=Cygwin
        _use_oh_my_posh=0
        ;;
    MINGW*)
        MYCELIO_OS_NAME=Windows
        MYCELIO_OS_VARIANT=MINGW
        _use_oh_my_posh=0
        ;;
    MSYS*)
        MYCELIO_OS_NAME=Windows
        MYCELIO_OS_VARIANT=MSYS
        _use_oh_my_posh=0
        ;;
    esac

    if [ -x "$(command -v oh-my-posh)" ] && [ -f "$HOME/.poshthemes/stelbent.minimal.omp.json" ] && [ "$_use_oh_my_posh" = "1" ]; then
        _shell=$(oh-my-posh --print-shell)
        eval "$(oh-my-posh --init --shell "$_shell" --config "$HOME/.poshthemes/stelbent.minimal.omp.json")"
    fi

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

    alias refresh='git -C "$MYCELIO_ROOT" pull >/dev/null 2>&1 || source "$MYCELIO_ROOT/linux/.profile"'

    alias less='less -r'
    alias more='less -r'

    # Add an "alert" alias for long running commands.  Use like so:
    #   sleep 10; alert
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

    if [ "$MYCELIO_OS_NAME" = "macOS" ]; then
        alias dir='dir -G'
        alias vdir='vdir -G'

        alias grep='grep -G'
        alias fgrep='fgrep -G'
        alias egrep='egrep -G'

        alias ll='ls -alF -G'
        alias ls='ls -alF -G'
        alias la='ls -A -G'
        alias l='ls -CF -G'
    else
        alias dir='dir --color=auto'
        alias vdir='vdir --color=auto'

        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'

        alias ll='ls -alF --color=always'
        alias ls='ls -alF --color=always'
        alias la='ls -A --color=always'
        alias l='ls -CF --color=always'
    fi

    echo "▓▓░░"
    echo "▓▓░░   ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
    echo "▓▓░░   ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
    echo "▓▓░░   ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
    echo "▓▓░░"
    echo "▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≡≡≡"
    echo ""
    echo "Initialized '${MYCELIO_OS_NAME}:${MYCELIO_OS_VARIANT}' environment: '$MYCELIO_ROOT'"
    echo "Parent Process: $_parent"
    echo ""
    echo "  refresh     Try to pull latest 'dotfiles' and reload profile"
    echo "  micro       Default text editor. Press 'F2' to save and 'F4' to exit."
    echo "  gpgtest     Validate that git commit signing will work with secret key"
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
    export MYCELIO_GOROOT="$HOME/.local/go"
    export MYCELIO_GOBIN="$MYCELIO_GOROOT/bin"
    mkdir -p "$MYCELIO_GOROOT"

    _add_path "prepend" "${GOBIN:-}"
    _add_path "prepend" "${MYCELIO_GOBIN:-}"

    _go_exe="$MYCELIO_GOBIN/bin/go"
    if [ -f "$_go_exe" ]; then
        export GOROOT="$MYCELIO_GOROOT"
        export GOBIN="$MYCELIO_GOBIN"
        unset GOPATH
        "$_go_exe" env -w GOROOT="$GOROOT"
        "$_go_exe" env -w GOBIN="$GOROOT/bin"
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

    # This is critically important on Windows (MSYS) otherwise we are not able to
    # create symbolic links which is the entire point of 'stow'
    export MSYS=winsymlinks:nativestrict

    if _tty="$(tty)"; then
        GPG_TTY="$_tty"
        export GPG_TTY
    fi

    # We do this near the beginning because Synology may not even define "HOME" variable
    # which we rely heavily on.
    if uname -a | grep -q "synology"; then
        _initialize_synology
    fi

    # Import environment varaibles from dotenv file. Primarily used to grab
    # the 'MYCELIO_ROOT' path as it is sometimes hard (if not impossible) to calculate
    # on some shells/platforms. If needed, this could be replaced with something
    # more advanced e.g., https://github.com/ko1nksm/shdotenv
    dotenv="$HOME/.env"
    if [ -f "$dotenv" ]; then
        OLD_IFS=$IFS
        IFS="$(printf '\n ')"
        IFS="${IFS% }"

        # shellcheck disable=SC2013
        for _line in $(grep -v '^#.*' "$dotenv"); do
            if [ -n "${_line:-}" ]; then
                eval "export $_line"
            fi
        done

        IFS=$OLD_IFS
    fi

    if [ -z "${MYCELIO_ROOT:-}" ]; then
        export MYCELIO_ROOT="$HOME/dotfiles"
    fi

    export LD_PRELOAD=

    _add_path "prepend" "/mingw64/bin"
    _add_path "prepend" "/clang64/bin"
    _add_path "prepend" "/mnt/c/Program Files/Microsoft VS Code/bin"

    _add_path "prepend" "/usr/bin"
    _add_path "prepend" "/usr/local/gnupg/bin"
    _add_path "prepend" "$HOME/.local/bin"
    _add_path "prepend" "$HOME/.local/sbin"
    _add_path "prepend" "$HOME/.config/git-fuzzy/bin"

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
