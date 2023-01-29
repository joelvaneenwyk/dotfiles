function install_oh_my_posh {
    if [ ! -f "$MYCELIO_HOME/.poshthemes/stelbent.minimal.omp.json" ]; then
        _posh_themes="$MYCELIO_HOME/.poshthemes"
        mkdir -p "$_posh_themes"
        run_task "posh.themes.get" get_file "$_posh_themes/themes.zip" "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"

        if [ -x "$(command -v unzip)" ]; then
            run_task "posh.themes.unzip" unzip -o "$_posh_themes/themes.zip" -d "$_posh_themes"
        elif [ -x "$(command -v 7z)" ]; then
            run_task "posh.themes.7z" 7z e "$_posh_themes/themes.zip" -o"$_posh_themes" -r
        else
            echo "Neither 'unzip' nor '7z' commands available to extract oh-my-posh themes."
        fi

        chmod u+rw ~/.poshthemes/*.json
        rm -f "$_posh_themes/themes.zip"
    fi

    font_base_name="JetBrains Mono"
    font_base_filename=${font_base_name// /}
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$font_base_filename.zip"
    _fonts_path="$MYCELIO_HOME/.fonts"

    if [ ! -f "$_fonts_path/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
        mkdir -p "$_fonts_path"
        run_task "font.jetbrains.get" get_file "$_fonts_path/$font_base_filename.zip" "$font_url"

        if [ -x "$(command -v unzip)" ]; then
            run_task "fonts.unzip" unzip -o "$_fonts_path/$font_base_filename.zip" -d "$_fonts_path"
        elif [ -x "$(command -v 7z)" ]; then
            run_task "fonts.7z" 7z e "$_fonts_path/$font_base_filename.zip" -o"$_fonts_path" -r
        else
            echo "Neither 'unzip' nor '7z' commands available to extract fonts."
        fi

        chmod u+rw "$MYCELIO_HOME/.fonts"
        rm -f "$_fonts_path/$font_base_filename.zip"

        if [ -x "$(command -v fc-cache)" ]; then
            if fc-cache -fv >/dev/null 2>&1; then
                echo "✔ Flushed font cache."
            else
                echo "⚠ Failed to flush font cache."
            fi
        else
            echo "⚠ Unable to flush font cache as 'fc-cache' is not installed"
        fi
    fi

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped install of 'oh-my-posh' for root user."
        return 0
    fi

    _oh_my_posh_tmp="$MYCELIO_TEMP/oh_my_posh"
    _oh_my_posh_exe="$MYCELIO_GOBIN/oh-my-posh${MYCELIO_OS_APP_EXTENSION:-}"

    if [ -f "$MYCELIO_HOME/.local/bin/oh-my-posh" ]; then
        rm "$MYCELIO_HOME/.local/bin/oh-my-posh"
        echo "✔ Removed 'oh-my-posh' executable old location."
    fi

    if [ -f "$_oh_my_posh_exe" ]; then
        if [ ! "${MYCELIO_ARG_CLEAN:-}" = "1" ] && _version=$("$_oh_my_posh_exe" --version 2>&1) && [ "$_version" = "8.32.4" ]; then
            echo "✔ 'oh-my-posh' v$_version already installed."
            return 0
        else
            rm -rf "$_oh_my_posh_tmp"
            rm -f "$_oh_my_posh_exe"
            echo "Removed oh-my-posh binary: '$_oh_my_posh_exe'"
        fi
    fi

    _posh_archive="posh-$MYCELIO_OS-$MYCELIO_ARCH$MYCELIO_OS_APP_EXTENSION"
    _posh_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/$_posh_archive"
    if run_task "posh.get" get_file "$_oh_my_posh_exe" "$_posh_url"; then
        chmod +x "$_oh_my_posh_exe"
    fi

    if ! _version=$("$_oh_my_posh_exe" --version 2>&1); then
        if [ ! -x "$(command -v git)" ]; then
            log_error "Failed to install 'oh-my-posh' extension. Required 'git' tool missing."
            return 1
        fi

        if [ ! -f "$MYCELIO_GOEXE" ]; then
            log_error "Failed to install 'oh-my-posh' extension. Missing 'go' compiler: '$MYCELIO_GOEXE'"
            return 2
        fi

        if [ -f "$MYCELIO_GOEXE" ]; then
            mkdir -p "$_oh_my_posh_tmp"
            rm -rf "$_oh_my_posh_tmp"
            run_task "oh-my-posh.git.clone" git -c advice.detachedHead=false clone -b "v7.26.0" "https://github.com/JanDeDobbeleer/oh-my-posh.git" "$_oh_my_posh_tmp"

            if (
                cd "$_oh_my_posh_tmp/src"

                GOHOSTOS="$MYCELIO_OS"
                export GOHOSTOS

                GOARCH="$MYCELIO_ARCH"
                export GOARCH

                GOARM="$MYCELIO_ARM"
                export GOARM

                GOHOSTARCH="$MYCELIO_ARCH"
                export GOHOSTARCH

                # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/.github/workflows/release.yml
                run_task "oh-my-posh.build" "$MYCELIO_GOEXE" build -a -ldflags "-extldflags -static" -o "$_oh_my_posh_exe"
            ); then
                echo "Successfully installed 'oh-my-posh' site builder."
            else
                echo "Failed to install 'oh-my-posh' site builder."
            fi
        fi
    fi

    if ! _version=$("$_oh_my_posh_exe" --version 2>&1); then
        log_error "Failed to install 'oh-my-posh' terminal helper."
        return 3
    fi

    echo "✔ Installed 'oh-my-posh' v$_version."

    return 0
}
