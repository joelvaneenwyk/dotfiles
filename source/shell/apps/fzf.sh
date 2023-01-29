function install_fzf {
    _local_root="$MYCELIO_HOME/.local"
    _fzf_root="$_local_root/fzf"
    _fzf_exe="$_local_root/bin/fzf${MYCELIO_OS_APP_EXTENSION:-}"

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_fzf_root"
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'fzf' install for root user."
        return 0
    fi

    if [ -d "$_fzf_root" ] && [ -f "$_fzf_exe" ]; then
        echo "✔ 'fzf' already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Required 'git' tool missing."
        return 0
    fi

    if [ ! -f "$MYCELIO_GOEXE" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Missing 'go' compiler: '$MYCELIO_GOEXE'"
        return 0
    fi

    if [ ! -x "$(command -v make)" ]; then
        echo "⚠ WARNING: Failed to install 'fzf' extension. Required 'make' tool missing."
        return 0
    fi

    mkdir -p "$_fzf_root"
    rm -rf "$_fzf_root"
    run_task "fzf.git.clone" git -c advice.detachedHead=false clone -b "0.27.2" "https://github.com/junegunn/fzf.git" "$_fzf_root"

    if (
        cd "$_fzf_root"
        run_task "fzf.build" "$MYCELIO_GOEXE" build -a -ldflags "-s -w" -o "$_fzf_exe"
    ); then
        echo "✔ Successfully generated 'fzf' utility with 'go' compiler."
    else
        log_error "Failed to install 'fzf' utility."
    fi

    if [ ! -f "$_fzf_exe" ]; then
        log_error "Failed to compile 'fzf' utility."
        return 3
    fi

    echo "fzf v$("$_fzf_exe" --version)"

    return 0
}
