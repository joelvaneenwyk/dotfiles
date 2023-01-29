function install_hugo {
    _hugo_tmp="$MYCELIO_TEMP/hugo"
    _hugo_exe="$MYCELIO_GOBIN/hugo$MYCELIO_OS_APP_EXTENSION"

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'hugo' install for root user."
        return 0
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_hugo_tmp"
    fi

    if [ -f "$_hugo_exe" ] && "$_hugo_exe" version; then
        echo "✔ 'hugo' site builder already installed."
        return 0
    fi

    if [ ! -x "$(command -v git)" ]; then
        log_error "Failed to install 'hugo' site builder. Required 'git' tool missing."
        return 1
    fi

    if [ ! -f "$MYCELIO_GOEXE" ]; then
        log_error "Failed to install 'hugo' site builder. Missing 'go' compiler: '$MYCELIO_GOEXE'"
        return 2
    fi

    if [ -f "$MYCELIO_GOEXE" ]; then
        mkdir -p "$_hugo_tmp"
        rm -rf "$_hugo_tmp"
        run_task "hugo.git.clone" git -c advice.detachedHead=false clone -b "v0.100.0" "https://github.com/gohugoio/hugo.git" "$_hugo_tmp"

        if (
            cd "$_hugo_tmp"

            GOHOSTOS="$MYCELIO_OS"
            export GOHOSTOS

            GOARCH="$MYCELIO_ARCH"
            export GOARCH

            GOARM="$MYCELIO_ARM"
            export GOARM

            GOHOSTARCH="$MYCELIO_ARCH"
            export GOHOSTARCH

            # Note that CGO_ENABLED allows the creation of Go packages that call C code. There
            # is no support for GCC on Synology so not able to build extended features.
            if uname -a | grep -q "synology"; then
                CGO_ENABLED="0" run_task "hugo.build" "$MYCELIO_GOEXE" build -v -ldflags "-extldflags -static" -o "$_hugo_exe"
            else
                # https://github.com/gohugoio/hugo/blob/master/goreleaser.yml
                CGO_ENABLED="1" run_task "hugo.build" "$MYCELIO_GOEXE" build -v -tags extended -o "$_hugo_exe"
            fi
        ); then
            echo "✔ Successfully installed 'hugo' site builder."
        else
            log_error "Failed to install 'hugo' site builder."
        fi
    fi

    if [ ! -f "$_hugo_exe" ] || ! "$_hugo_exe" version; then
        log_error "Failed to install 'hugo' static site builder."
        return 3
    fi

    return 0
}
