function _stow_internal() {
    _source="$1"
    _target="$2"
    shift 2

    _remove=0

    if [ -f "$_target" ] || [ -d "$_target" ] || [ -L "$_target" ]; then
        _remove=1
    fi

    if [ ! -L "$_target" ]; then
        _real="$(get_real_path "$_target")"

        # Do not delete files or directories that are actually inside the
        # dot files source directory.
        if [[ "$_real" == *"$MYCELIO_ROOT"* ]]; then
            _remove=0
            echo "🔗 SKIPPED: $_target"
        fi
    fi

    if [ "$_remove" = "1" ]; then
        _name="'$_target'"
        if [ -L "$_target" ]; then
            _name="$_name (link)"
        fi

        if [ -f "$_source" ]; then
            _name="$_name (file)"
            if [[ "$*" == *"--delete"* ]]; then
                if rm -f "$_target" >/dev/null 2>&1; then
                    echo "REMOVED: $_name"
                else
                    echo "SKIPPED: $_name"
                fi
            else
                echo "TARGET: $_name"
            fi
        elif [ -d "$_source" ]; then
            _name="$_name (directory)"
            if [[ "$*" == *"--delete"* ]]; then
                # Remove empty directories in target. It will not delete directories
                # that have files in them.
                if find "$_target" -type d -empty -delete >/dev/null 2>&1 &&
                    rm -df "$_target" >/dev/null 2>&1; then
                    echo "REMOVED: $_name"
                else
                    echo "SKIPPED: $_name"
                fi
            else
                echo "TARGET: $_name"
            fi
        fi
    fi

    if [[ ! "$*" == *"--delete"* ]] && [ ! -f "$_stow_bin" ]; then
        if [ -f "$_source" ]; then
            mkdir -p "$(dirname "$_target")"
        fi

        if [ -f "$_source" ] || [ -d "$_source" ]; then
            if ln -s "$_source" "$_target" >/dev/null 2>&1; then
                echo "✔ Stowed target: '$_target'"
            else
                log_error "Unable to stow target: '$_target'"
            fi
        fi
    fi
}

function _stow() {
    _stow_bin="$MYCELIO_STOW_ROOT/bin/stow"
    _target_path="$MYCELIO_HOME"

    for _package in "$@"; do
        _offset=$"packages/$_package"
        _root="$MYCELIO_ROOT/$_offset"
        if [ -d "$_root" ]; then
            if [ -x "$(command -v git)" ] && [ -d "$MYCELIO_ROOT/.git" ]; then
                # Remove files from directories first and then the directory but only if
                # it is empty.
                {
                    git -C "$MYCELIO_ROOT" ls-tree -r --name-only HEAD "packages/$_package"
                    (git -C "$MYCELIO_ROOT" ls-tree -r -d --name-only HEAD "packages/$_package" | tac)
                } | while IFS= read -r line; do
                    _source="${MYCELIO_ROOT%/}/$line"
                    _target="${_target_path%/}/${line/$_offset\//}"
                    _stow_internal "$_source" "$_target" "$@"
                done
            else
                find "$_root" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
                    _source="$file"
                    _target="$HOME/${file//$_root\//}"
                    _stow_internal "$_source" "$_target" "$@"
                done
            fi
        fi
    done

    if [ -f "$_stow_bin" ] && [[ ! "$*" == *"--delete"* ]]; then
        # NOTE: We filter out spurious 'find_stowed_path' error due to https://github.com/aspiers/stow/issues/65
        _stow_args=("--dir=$MYCELIO_ROOT/packages" "--target=$_target_path" "--verbose")
        _stow_args+=("$@")

        _return_code=0
        if run_command "stow" perl -I "$MYCELIO_STOW_ROOT/lib" "$_stow_bin" "${_stow_args[@]}" 2>&1 | grep -v "BUG in find_stowed_path"; then
            _return_code="${PIPESTATUS[0]}"
        else
            _return_code="${PIPESTATUS[0]}"
        fi

        if [ "$_return_code" = "0" ]; then
            echo "✔ Stow command succeeded."
        else
            log_error "Stow failed."
            return "$_return_code"
        fi
    fi

    return 0
}

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

function stow_packages() {
    _stow "$@" shell
    _stow "$@" fonts
    _stow "$@" vim

    # We intentionally stow 'fish' config first to populate the directories
    # and then we create additional links (e.g. keybindings) and download
    # the fish package manager fundle, see https://github.com/danhper/fundle
    _stow "$@" fish

    if [ "${MYCELIO_OS:-}" = "darwin" ]; then
        mkdir -p "$MYCELIO_HOME/Library/Application\ Support/Code"

        # todo : Revisit enabling this at some point after settings are improved
        # _stow "$@" macos
    fi
}

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#
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
