function install_micro_text_editor() {
    mkdir -p "$MYCELIO_HOME/.local/bin/"
    _micro_exe="micro$MYCELIO_OS_APP_EXTENSION"

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -f "$MYCELIO_HOME/.local/bin/$_micro_exe"
    fi

    # Install micro text editor. It is optional so ignore failures
    if [ -f "$MYCELIO_HOME/.local/bin/$_micro_exe" ]; then
        echo "✔ micro text editor already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ] || [ ! -x "$(command -v make)" ]; then
        echo "Skipped 'micro' compile. Missing build tools."
    else
        _tmp_micro="$MYCELIO_TEMP/micro"
        mkdir -p "$_tmp_micro"
        rm -rf "$_tmp_micro"
        run_task "micro.git.clone" git -c advice.detachedHead=false clone -b "v2.0.10" "https://github.com/zyedidia/micro" "$_tmp_micro"

        if (
            cd "$_tmp_micro"
            run_task "micro.make" make build
        ); then
            if [ -f "$_tmp_micro/$_micro_exe" ]; then
                rm -f "$MYCELIO_HOME/.local/bin/$_micro_exe"
                mv "$_tmp_micro/$_micro_exe" "$MYCELIO_HOME/.local/bin/"
            fi

            echo "✔ Successfully compiled micro text editor."
        fi
    fi

    if [ ! -f "$MYCELIO_HOME/.local/bin/$_micro_exe" ]; then
        if (
            mkdir -p "$MYCELIO_HOME/.local/bin/"
            cd "$MYCELIO_HOME/.local/bin/"
            install_micro="$MYCELIO_HOME/.local/bin/micro_install.sh"
            run_task "micro.get" get_file "$install_micro" "https://getmic.ro"
            chmod a+x "$install_micro"
            run_task "micro.install" "$install_micro"
        ); then
            echo "[mycelio] Successfully installed 'micro' text editor."
        else
            echo "[mycelio] WARNING: Failed to install 'micro' text editor."
            return 2
        fi
    fi

    return 0
}
