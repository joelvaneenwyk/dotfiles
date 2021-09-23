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
            _left="${_list%:"$dir":*}" # remove last occurrence to end
            if [ "$_list" = "$_left" ]; then
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
    _list=":$(_unique_list "${1-}"):"
    shift

    case "$1" in
    'include' | 'prepend' | 'append')
        _action="$1"
        shift
        ;;
    *)
        _action='include'
        ;;
    esac

    for dir in "$@"; do
        # Remove last occurrence to end
        _left="${_list%:$dir:*}"

        if [ "$_list" = "$_left" ]; then
            # Input list does not contain $dir
            [ "$_action" = 'include' ] && _action='append'
            _right=''
        else
            # Remove start to last occurrence
            _right=":${_list#$_left:$dir:}"
        fi

        # Construct _list with $dir added
        case "$_action" in
        'prepend') _list=":$dir$_left$_right" ;;
        'append') _list="$_left$_right$dir:" ;;
        esac
    done

    # Strip ':' pads
    _list="${_list#:}"
    _list="${_list%:}"

    # Return combined path
    printf '%s' "$_list"
}

#
# USAGE: _add_path [include|prepend|append] "dir1" "dir2" ...
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

_set_golang_paths() {
    export MYCELIO_GOROOT="$HOME/.local/go"
    export MYCELIO_GOBIN="$MYCELIO_GOROOT/bin"
    export MYCELIO_GOEXE="$MYCELIO_GOBIN/go$MYCELIO_OS_APP_EXTENSION"
    mkdir -p "$MYCELIO_GOROOT"

    _add_path "prepend" "${GOBIN:-}"
    _add_path "prepend" "${MYCELIO_GOBIN:-}"

    if [ -f "$MYCELIO_GOEXE" ]; then
        unset GOROOT
        unset GOBIN
        unset GOPATH
        "$MYCELIO_GOEXE" env -u GOPATH >/dev/null 2>&1 || true
        "$MYCELIO_GOEXE" env -u GOROOT >/dev/null 2>&1 || true
        "$MYCELIO_GOEXE" env -u GOBIN >/dev/null 2>&1 || true
    fi
}

_initialize_synology() {
    #This fixes the backspace when telnetting in.
    #if [ "$TERM" != "linux" ]; then
    #        stty erase
    #fi

    if [ "$(whoami)" = "root" ]; then
        HOME="${HOME:-/root}"
        export HOME

        USERNAME=root
        export USERNAME
    fi
}

initialize_interactive_profile() {
    # Make less more friendly for non-text input files, see lesspipe(1)
    [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

    # Set variable identifying the chroot you work in (used in the prompt below)
    if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
    fi

    # Set a fancy prompt (non-color, unless we know we "want" color)
    case "$TERM" in
    xterm-color | *-256color)
        color_prompt=yes
        ;;
    esac

    # Use a colored prompt if the terminal has the capability
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

    if [ "$color_prompt" = "yes" ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n \$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\n \$ '
    fi
    unset color_prompt force_color_prompt

    # If this is an xterm set the title to user@host:dir
    case "$TERM" in
    xterm* | rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *) ;;
    esac

    # Enable color support for 'ls'
    if [ -x /usr/bin/dircolors ]; then
        if [ -r "$HOME/.dircolors" ]; then
            eval "$(dircolors -b "$HOME/.dircolors")"
        else
            eval "$(dircolors -b)"
        fi
    fi

    # Colored GCC warnings and errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

    if [ -x "$(command -v oh-my-posh)" ] && [ "$MYCELIO_OH_MY_POSH" = "1" ]; then
        _shell=$(oh-my-posh --print-shell)
        _theme="$HOME/.poshthemes/mycelio.omp.json"
        if [ ! -f "$_theme" ] && [ -f "$HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
            _theme="$HOME/.poshthemes/stelbent.minimal.omp.json"
        fi

        if [ -n "$_shell" ] && [ -f "$_theme" ]; then
            if ! eval "$(oh-my-posh --init --shell "$_shell" --config "$_theme")"; then
                echo "❌ Failed to initialize Oh My Posh."
            fi
        fi
    fi

    if [ "${MYCELIO_OS_NAME:-}" = "Windows" ]; then
        if ! _parent="$(ps -p $$ --all | tail -n +2 | awk '{ print $8 }')"; then
            _parent="N/A"
        fi
    elif ! _parent="$(ps -o args= ${PPID:-0} 2>&1 | head -n 1)"; then
        _parent="N/A"
    fi

    alias mstow='perl -I "$MYCELIO_ROOT/source/stow/lib" "$MYCELIO_ROOT/source/stow/bin/stow"'

    alias gpgreset='gpg-connect-agent updatestartuptty /bye'
    alias pgptest='source "$MYCELIO_ROOT/source/shell/pgptest.sh"'
    alias gpgtest='source "$MYCELIO_ROOT/source/shell/pgptest.sh"'
    alias cls='clear'

    ## Common typos
    alias cd.='cd "$MYCELIO_ROOT"'
    alias cd~='cd ~'
    alias cd..='cd ..'
    alias cd~='cd ~'

    ## Faster way to move around
    alias ..='cd ..'
    alias ...='cd ../../../'
    alias ....='cd ../../../../'
    alias .....='cd ../../../../'
    alias .4='cd ../../../../'
    alias .5='cd ../../../../..'

    alias refresh='git -C "$MYCELIO_ROOT" pull >/dev/null 2>&1 || true; source "$MYCELIO_ROOT/packages/linux/.profile"'

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

    echo "▓├═════════════════════════════════"
    echo "▓│"
    echo "▓│   ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
    echo "▓│   ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
    echo "▓│   ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
    echo "▓│"
    echo "▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≡≡≡"
    echo ""
    echo "Initialized '${MYCELIO_OS_NAME:-UNKNOWN}:${MYCELIO_OS_VARIANT:-UNKNOWN}' environment: '${MYCELIO_ROOT:-}'"
    echo "Parent Process: $_parent"
    echo ""
    echo "  refresh     Try to pull latest 'dotfiles' and reload profile"
    echo "  micro       Default text editor. Press 'F2' to save and 'F4' to exit."
    echo "  gpgtest     Validate that git commit signing will work with secret key"
    echo ""

    return 0
}

initialize_profile() {
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
        for _line in $(grep -v '^#.*' "$dotenv" || ""); do
            if [ -n "${_line:-}" ]; then
                eval "export $_line" >/dev/null 2>&1 || true
            fi
        done

        IFS=$OLD_IFS
    fi

    # We intentionally disable on some Windows variants due to corruption e.g. MSYS, Cygwin
    MYCELIO_OH_MY_POSH=1

    MYCELIO_OS_NAME="UNKNOWN"
    MYCELIO_OS_VARIANT="$(uname -s)"
    MYCELIO_OS_APP_EXTENSION=""

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
        MYCELIO_OS_APP_EXTENSION=.exe
        MYCELIO_OH_MY_POSH=0
        ;;
    MINGW*)
        MYCELIO_OS_NAME=Windows
        MYCELIO_OS_VARIANT=MINGW
        MYCELIO_OS_APP_EXTENSION=.exe
        MYCELIO_OH_MY_POSH=0
        ;;
    MSYS*)
        MYCELIO_OS_NAME=Windows
        MYCELIO_OS_VARIANT=MSYS
        MYCELIO_OS_APP_EXTENSION=.exe
        MYCELIO_OH_MY_POSH=0
        ;;
    esac
    export MYCELIO_OS_NAME MYCELIO_OS_VARIANT MYCELIO_OS_APP_EXTENSION MYCELIO_OH_MY_POSH

    if [ -z "${MYCELIO_ROOT:-}" ]; then
        export MYCELIO_ROOT="$HOME/dotfiles"
    fi

    # Make sure that USER is defined because some scripts (e.g. Oh My Posh) expect
    # the variable to be defined.
    export USER=${USER:-"$(whoami)"}

    # Define a default for this as it is used by Oh My Posh and we do not want an
    # error due to undefined access.
    export PROMPT_COMMAND=${PROMPT_COMMAND:-""}

    export LD_PRELOAD=

    _set_golang_paths

    # Must NOT include /mingw64/bin as we want to rely on the system environment setup
    # to specify those.
    _add_path "prepend" "/usr/local/gnupg/bin"
    _add_path "prepend" "$HOME/.local/go/bin"
    _add_path "prepend" "$HOME/.local/bin"
    _add_path "prepend" "$HOME/.local/sbin"

    _add_path "append" "$HOME/.asdf/bin"

    # Add 'dot' (current directory) to list of inputs which is required on some versions
    # of Tex on some operating systems.
    export TEXINPUTS=.:${TEXINPUTS:-}

    if [ "${MSYSTEM:-}" = "MSYS" ]; then
        _add_path "prepend" "/usr/bin"

        if _gcc_version=$(gcc --version | grep gcc | awk '{print $3}' 2>&1); then
            _gcc_lib_root="/usr/lib/gcc/$MSYSTEM_CHOST/$_gcc_version"
        fi

        if [ -d "${_gcc_lib_root:-}" ]; then
            export GCC_PLUGIN_PATH="$_gcc_lib_root"
            _add_path "prepend" "$_gcc_lib_root"

            # Add global C and C++ include path. This should be included by default but is
            # not and results in errors when building Perl dependencies on MSYS.
            CPATH="/usr/lib/gcc/$MSYSTEM_CHOST/$_gcc_version/include;${CPATH:-}"
            export CPATH
        fi
    elif [ "${MSYSTEM:-}" = "MINGW64" ] && [ -f "/mingw64/bin/tex.exe" ]; then
        _add_path "prepend" "/mingw64/bin"
        _add_path "prepend" "/usr/bin"

        export TEX="/mingw64/bin/tex"
        export TEX_OS_NAME="win32"
    fi

    _add_path "append" "/mnt/c/Program Files/Microsoft VS Code/bin"
    _add_path "append" "/c/Program Files/Microsoft VS Code/bin"
    _add_path "append" "$HOME/.config/git-fuzzy/bin"

    # Clear out TMP as TEMP may come from Windows and we do not want tools confused
    # if they find both.
    unset TMP
    unset temp
    unset tmp
}

initialize() {
    initialize_profile "$@"

    # If not running interactively, don't do anything else.
    case $- in
    *i*) ;;
    *)
        return
        ;;
    esac

    initialize_interactive_profile "$@"
}

initialize "$@"
