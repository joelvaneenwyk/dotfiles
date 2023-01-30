#!/bin/bash

function initialize_gitconfig() {
    _git_config="$MYCELIO_HOME/.gitconfig"

    local windows_root
    windows_root="$(get_windows_root)"

    if [ ! -f "$_git_config" ] || rm -f "$_git_config"; then
        unlink "$_git_config" >/dev/null 2>&1 || true

        {
            echo "[include]"

            if is_windows; then
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_common")"
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_linux")"
                echo "    path = $(cygpath --mixed "$MYCELIO_ROOT/source/git/.gitconfig_windows")"
                echo "    path = $(cygpath --mixed "$MYCELIO_HOME/.gitconfig_mycelio")"
            elif [ "$MYCELIO_OS" = "darwin" ]; then
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_common"
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_macos"
                echo "    path = $MYCELIO_HOME/.gitconfig_mycelio"
            else
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_common"
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_linux"
                echo "    path = $MYCELIO_HOME/.gitconfig_mycelio"
            fi

            if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
                echo "    path = $MYCELIO_ROOT/source/git/.gitconfig_wsl"
            fi
        } >"$_git_config"

        {
            _gpg_paths=(
                "$windows_root/Program Files (x86)/GnuPG/bin/gpg.exe"
                "$(get_profile_root)/scoop/apps/gnupg/current/bin/gpg.exe"
            )
            for _gpg in "${_gpg_paths[@]}"; do
                if [ -f "$_gpg" ] && ! grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
                    _gpg="$(cygpath --mixed "$_gpg")"
                    echo "[gpg]"
                    echo "    program = \"$_gpg\""
                    break
                fi
            done
        } >"$MYCELIO_HOME/.gitconfig_mycelio"

        echo "Created custom '.gitconfig' with include directives."
    fi

    # We only create the local version and never global config at '/etc/gnupg' since typical
    # user does not have access.
    _config_paths=(
        "$MYCELIO_HOME/.gnupg"
    )

    if [ -n "$windows_root" ] && ! grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        _config_paths+=(
            # GPG4Win: homedir
            "$windows_root/Users/$(whoami)/AppData/Roaming/gnupg"

            # GPG4Win: sysconfdir
            "$windows_root/ProgramData/GNU/etc/gnupg"

            # Scoop persistent storage
            "$windows_root/Users/$(whoami)/scoop/persist/gnupg/home"
        )
    fi

    for _config_path in "${_config_paths[@]}"; do
        generate_gnugp_config "$_config_path"
    done

    if _tty="$(tty)"; then
        GPG_TTY="$_tty"
        export GPG_TTY
    fi

    if [ -x "$(command -v gpgconf)" ]; then
        run_command "gpgconf.kill" gpgconf --kill gpg-agent
        if run_command "gpgconf.reload" gpgconf --reload; then
            echo "Reloaded 'gpgconf' tool."
        fi
    fi

    if [ -x "$(command -v gpg-connect-agent)" ]; then
        run_command "gpg.connect" gpg-connect-agent updatestartuptty /bye >/dev/null
    fi
}

function _update_git_repository() {
    _path="$1"
    _branch="$2"
    _remote="${3:-}"
    _name=$(basename "$_path")

    if [ -n "${_remote:-}" ]; then
        run_command "$_name.git.remote" git -C "$MYCELIO_ROOT/$_path" remote set-url "origin" "$_remote"
    fi

    run_command "$_name.git.fetch" git -C "$MYCELIO_ROOT/$_path" fetch

    if ! git -C "$MYCELIO_ROOT/$_path" symbolic-ref -q HEAD >/dev/null 2>&1; then
        run_command "$_name.git.checkout" git -C "$MYCELIO_ROOT/$_path" checkout "$_branch"
    fi

    run_command "$_name.git.pull" git -C "$MYCELIO_ROOT/$_path" pull "origin" "$_branch" --rebase --autostash
}
