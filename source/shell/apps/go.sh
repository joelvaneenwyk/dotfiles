function install_go {
    _local_root="$MYCELIO_HOME/.local"
    _local_go_root="$_local_root/go"
    _local_go_bootstrap_root="$_local_root/gobootstrap"
    _go_bootstrap_exe="$_local_go_bootstrap_root/bin/go"
    _go_requires_update=0
    _go_required_version_minor=18

    if [ "$(whoami)" == "root" ] && uname -a | grep -q "synology"; then
        echo "Skipped 'go' install for root user."
        return 0
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -rf "$_local_go_root"
        rm -rf "$_local_go_bootstrap_root"
    fi

    export MYCELIO_GOROOT="${MYCELIO_GOROOT:-$HOME/.local/go}"
    export MYCELIO_GOBIN="${MYCELIO_GOBIN:-$MYCELIO_GOROOT/bin}"
    export MYCELIO_GOEXE="${MYCELIO_GOEXE:-$MYCELIO_GOBIN/go${MYCELIO_OS_APP_EXTENSION:-}}"

    if [ -f "$MYCELIO_GOEXE" ] && _go_version="$("$MYCELIO_GOEXE" version 2>&1 | (
        read -r _ _ v _
        echo "${v#go}"
    ))"; then
        _go_version_minor=$(echo "$_go_version" | cut -d. -f2)
        if [ "$_go_version_minor" -lt "$_go_required_version_minor" ]; then
            _go_requires_update=1
        fi
    else
        _go_requires_update=1
    fi

    if [ "${MSYSTEM:-}" = "MSYS" ]; then
        _go_os="linux"
    else
        _go_os="$MYCELIO_OS"
    fi

    if [ "$_go_requires_update" = "1" ]; then
        _go_version="1.$_go_required_version_minor"
        _go_compiled=0

        if [ ! -x "$(command -v gcc)" ] && [ ! -x "$(command -v make)" ]; then
            log_error "Skipped 'go' compile. Missing GCC toolchain."
        else
            if [ "${MSYSTEM:-}" = "MSYS" ]; then
                # https://golang.org/doc/install/source
                _go_bootstrap_archive="$MYCELIO_TEMP/go1.4.windows-amd64.zip"
                run_task "go.bootstrap.get" get_file "$_go_bootstrap_archive" "https://golang.org/dl/go1.4.windows-amd64.zip"
                echo "Extracting 'go' binaries: '$_go_bootstrap_archive'"
                rm -rf "$MYCELIO_TEMP/go" || true
                run_task "go.bootstrap.tar" tar -C "$MYCELIO_TEMP" -xzf "$_go_bootstrap_archive"
                rm -rf "$_local_go_bootstrap_root" || true
                mv "$MYCELIO_TEMP/go" "$_local_go_bootstrap_root"
                rm "$_go_bootstrap_src_archive"

                if [ -f "$_go_bootstrap_exe" ]; then
                    echo "✔ Using pre-built 'go' compiler for MSYS environment."
                else
                    if [ -f "/mingw64/bin/go" ]; then
                        _go_bootstrap_exe="/mingw64/bin/go"
                        _local_go_bootstrap_root=$($_go_bootstrap_exe env GOROOT)
                    else
                        log_error "Missing required 'go' compiler for MSYS environment."
                    fi
                fi
            elif [ ! -f "$_go_bootstrap_exe" ]; then
                # https://golang.org/doc/install/source
                _go_bootstrap_src_archive="$MYCELIO_TEMP/go_bootstrap.tgz"
                run_task "go.bootstrap.get" get_file "$_go_bootstrap_src_archive" "https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz"
                rm -rf "$MYCELIO_TEMP/go" || true
                run_task "go.bootstrap.tar" tar -C "$MYCELIO_TEMP" -xzf "$_go_bootstrap_src_archive"
                rm -rf "$_local_go_bootstrap_root" || true
                mv "$MYCELIO_TEMP/go" "$_local_go_bootstrap_root"
                rm "$_go_bootstrap_src_archive"

                if (
                    GOROOT_FINAL="$_local_go_bootstrap_root"
                    export GOROOT_FINAL

                    GOOS="$_go_os"
                    export GOOS

                    GOHOSTOS="$_go_os"
                    export GOHOSTOS

                    GOARCH="$MYCELIO_ARCH"
                    export GOARCH

                    GOARM="$MYCELIO_ARM"
                    export GOARM

                    GOHOSTARCH="$MYCELIO_ARCH"
                    export GOHOSTARCH

                    # shellcheck disable=SC2031
                    export CGO_ENABLED=0
                    cd "$_local_go_bootstrap_root/src"

                    if [ -x "$(command -v cygpath)" ]; then
                        if [ "${MSYSTEM:-}" = "MSYS" ]; then
                            export GO_LDFLAGS="--subsystem,console"
                        fi

                        run_task "go.bootstrap.make" cmd "\/d" "\/c" "$_local_go_bootstrap_root/src/make.bat"
                    else
                        run_task "go.bootstrap.make" ./make.bash
                    fi

                    unset GOROOT_FINAL
                ); then
                    echo "Compiled 'go' bootstrap from source: '$_local_go_bootstrap_root/src'"
                else
                    log_error "Failed to compile 'go' bootstrap from source."
                fi
            fi

            # https://golang.org/doc/install/source
            if [ -f "$_go_bootstrap_exe" ]; then
                _go_src_archive="$MYCELIO_TEMP/go.tgz"
                run_task "go.get" get_file "$_go_src_archive" "https://dl.google.com/go/go$_go_version.src.tar.gz"

                run_task "go.source.extract" tar -C "$_local_root" -xzf "$_go_src_archive"
                rm "$_go_src_archive"

                if (
                    cd "$_local_go_root/src"

                    GOROOT_BOOTSTRAP="$($_go_bootstrap_exe env GOROOT)"
                    export GOROOT_BOOTSTRAP

                    GOOS="$_go_os"
                    export GOOS

                    GOHOSTOS="$_go_os"
                    export GOHOSTOS

                    GOARCH="$MYCELIO_ARCH"
                    export GOARCH

                    GOARM="$MYCELIO_ARM"
                    export GOARM

                    GOHOSTARCH="$MYCELIO_ARCH"
                    export GOHOSTARCH

                    if [ -x "$(command -v cygpath)" ]; then
                        run_task "go.make" cmd "\/d" "\/c" "$_local_go_root/src/make.bat"
                    else
                        run_task "go.make" ./make.bash
                    fi

                    if [ ! -f "$MYCELIO_GOEXE" ]; then
                        exit 2
                    fi

                    # Pre-compile the standard library, just like the official binary release tarballs do
                    run_command "go.install.std" "$MYCELIO_GOEXE" install std
                ); then
                    echo "✔ Compiled 'go' from source.: '$_local_go_root/src'"
                    _go_compiled=1
                else
                    echo "⚠ Failed to compile 'go' from source."
                fi

                # Remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
                rm -rf "$_local_go_root/pkg/*/cmd"
                rm -rf "$_local_go_root/pkg/bootstrap"
                rm -rf "$_local_go_root/pkg/obj"
                rm -rf "$_local_go_root/pkg/tool/*/api"
                rm -rf "$_local_go_root/pkg/tool/*/go_bootstrap "
                rm -rf "$_local_go_root/src/cmd/dist/dist"
            else
                echo "Missing required tools to compile 'go' from source."
            fi
        fi

        if [ "$_go_compiled" = "0" ]; then
            if _uname_output="$(uname -s 2>/dev/null)"; then
                case "${_uname_output}" in
                Linux*)
                    _go_archive="go$_go_version.linux-$MYCELIO_ARCH.tar.gz"
                    ;;
                Darwin*)
                    _go_archive="go$_go_version.darwin-$MYCELIO_ARCH.tar.gz"
                    ;;
                esac
            fi

            # Install Golang
            if [ -z "${_go_archive:-}" ]; then
                echo "⚠ Unsupported platform for installing 'go' language."
            else
                echo "Downloading archive: 'https://dl.google.com/go/$_go_archive'"
                run_task "go.source.get" get_file "$MYCELIO_TEMP/$_go_archive" "https://dl.google.com/go/$_go_archive"
                if [ ! -f "$MYCELIO_TEMP/$_go_archive" ]; then
                    echo "Failed to download 'go' archive."
                else
                    echo "Downloaded archive: '$_go_archive'"

                    _go_tmp="$MYCELIO_TEMP/go"
                    rm -rf "${_go_tmp:?}/"
                    if tar -xf "$MYCELIO_TEMP/$_go_archive" --directory "$MYCELIO_TEMP"; then
                        echo "Extracted 'go' archive: '$_go_tmp'"

                        mkdir -p "$_local_go_root/"
                        rm -rf "${_local_go_root:?}/"
                        cp -rf "$_go_tmp" "$_local_go_root"
                        echo "Updated 'go' install: '$_local_go_root'"
                    else
                        log_error "Failed to update 'go' install."
                    fi

                    rm -rf "$_go_tmp"
                    echo "Removed temporary 'go' files: '$_go_tmp'"
                fi
            fi
        fi
    fi

    if [ -f "$MYCELIO_GOEXE" ] && _go_version=$("$MYCELIO_GOEXE" version); then
        # The net package requires cgo by default because the host operating system
        # must in general mediate network call setup. On some systems, though, it is
        # possible to use the network without cgo, and useful to do so, for instance
        # to avoid dynamic linking. The new build tag netgo (off by default) allows
        # the construction of a net package in pure Go on those systems where it is possible.
        #   "$MYCELIO_GOEXE" build -tags netgo -a -v

        echo "✔ $_go_version"
    else
        log_error "Failed to install 'go' language."
        return 5
    fi

    return 0
}
