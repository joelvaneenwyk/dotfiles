function install_python() {
    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped Python setup for root user."
    elif [ -x "$(command -v python3)" ] && _python_version=$(python3 --version); then
        echo "$_python_version"

        if ! python3 -m pip --version >/dev/null 2>&1; then
            run_task "pip.get" get_file "$MYCELIO_TEMP/get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
            chmod a+x "$MYCELIO_TEMP/get-pip.py"
            run_task "pip.install" python3 "$MYCELIO_TEMP/get-pip.py"
        fi

        run_command "python.pip.upgrade" python3 -m pip install --user --upgrade pip

        # Could install with 'snapd' but there are issues with 'snapd' on WSL so to maintain
        # consistency between platforms and not install hacks we just use 'pip3' instead. For
        # details on the issue, see https://github.com/microsoft/WSL/issues/5126
        run_command "python.pip.precommit" python3 -m pip install --user pre-commit

        echo "✔ Upgraded 'pip3' and installed 'pre-commit' package."
    else
        log_error "Missing or invalid Python 3 install: $(command -v python3)"
    fi
}
