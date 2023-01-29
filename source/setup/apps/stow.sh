function install_stow() {
    MYCELIO_PERL="${MYCELIO_PERL:-$(command -v perl)}"
    export MYCELIO_PERL

    _cpan_temp_bin="$MYCELIO_TEMP/cpanm"

    if [ "${MSYSTEM:-}" = "MINGW64" ]; then
        _cpan_root="$MYCELIO_HOME/.cpan-w64"
        _cpanm_root="$MYCELIO_HOME/.cpanm-w64"
    else
        _cpan_root="$MYCELIO_HOME/.cpan"
        _cpanm_root="$MYCELIO_HOME/.cpanm"
    fi

    if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
        rm -f "$_cpan_temp_bin" >/dev/null 2>&1

        rm -f "$MYCELIO_HOME/.local/bin/cpanm" >/dev/null 2>&1

        rm -rf "$_cpan_root" >/dev/null 2>&1
        rm -rf "$_cpanm_root" >/dev/null 2>&1

        rm -f "$MYCELIO_STOW_ROOT/bin/stow" >/dev/null 2>&1
        rm -f "$MYCELIO_STOW_ROOT/bin/chkstow" >/dev/null 2>&1
    fi

    if [ ! -f "$MYCELIO_STOW_ROOT/configure.ac" ]; then
        log_error "'stow' source missing: '$MYCELIO_STOW_ROOT'"
        return 20
    elif (
        if [ "${MYCELIO_ARG_CLEAN:-}" = "1" ]; then
            # shellcheck source=source/stow/tools/make-clean.sh
            run_task "stow.make.clean" source "$MYCELIO_STOW_ROOT/tools/make-clean.sh"
        fi

        # shellcheck source=source/stow/tools/make-stow.sh
        run_task "stow.make" source "$MYCELIO_STOW_ROOT/tools/make-stow.sh"
    ); then
        echo "✔ Successfully built 'stow' from source."
    else
        log_error "Failed to build 'stow' from source."
        return 15
    fi

    # Remove intermediate Perl files in case another version of Perl generated
    # some files that are incompatible with current version.
    rm -rf "$MYCELIO_ROOT/_Inline"
    rm -rf "$MYCELIO_STOW_ROOT/_Inline"

    _stow --version
}
