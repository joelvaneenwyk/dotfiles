#!/bin/bash
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.
#

function edit() {
    input_file="$1.in"
    output_file="$1"

    # This is more explicit and reliable than the config file trick
    sed -e "s|[@]PERL[@]|$STOW_PERL|g" \
        -e "s|[@]VERSION[@]|$STOW_VERSION|g" \
        -e "s|[@]USE_LIB_PMDIR[@]|$USE_LIB_PMDIR|g" "$input_file" >"$output_file"
}

function make_docs() {
    if [ -e "$STOW_ROOT/.git" ] && [ -x "$(command -v git)" ]; then
        (
            git -C "$STOW_ROOT" log \
                --format="format:%ad  %aN <%aE>%n%n    * %w(70,0,4)%s%+b%n" \
                --name-status \
                v2.0.2..HEAD | sed 's/^\([A-Z]\)\t/      \1 /'
            cat "$STOW_ROOT/doc/ChangeLog.OLD"
        ) >"$STOW_ROOT/ChangeLog"
        echo "Rebuilt 'ChangeLog' from git commit history."
    else
        echo "Not in a git repository; can't update ChangeLog."
    fi

    if [ -f "$STOW_ROOT/automake/mdate-sh" ]; then
        # We intentionally want splitting so that each space separated part of the
        # date goes into a different argument.
        # shellcheck disable=SC2046
        set $("$STOW_ROOT/automake/mdate-sh" "$STOW_ROOT/doc/stow.texi")
    fi

    (
        printf "@set UPDATED %s %s %s\n" "${1:-0}" "${2:-0}" "${3:-0}"
        echo "@set UPDATED-MONTH ${2:-0} ${3:-0}"
        echo "@set EDITION $STOW_VERSION"
        echo "@set VERSION $STOW_VERSION"
    ) >"$STOW_ROOT/doc/version.texi"

    if [ -x "$(command -v makeinfo)" ]; then
        # Generate 'doc/stow.info' file needed for generating documentation. The makefile version
        # of this adds the "$STOW_ROOT/automake/missing" prefix to provide additional information
        # if it is unavailable but we skip that here since we do not assume you have already
        # executed 'autoreconf' so the 'missing' tool does not yet exist.
        makeinfo -I "$STOW_ROOT/doc/" -o "$STOW_ROOT/doc/" "$STOW_ROOT/doc/stow.texi"
    fi

    if [ -x "$(command -v pdfetex)" ]; then
        (
            cd "$STOW_ROOT/doc" || true
            TEXINPUTS="../;." run_command_group pdfetex "./stow.texi"
            mv "./stow.pdf" "./manual.pdf"
        )
        echo "✔ Used 'doc/stow.texi' to generate 'doc/manual.pdf'"
    fi
}

function make_stow() {
    set -e

    STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"

    # shellcheck source=./tools/stow-environment.sh
    source "$STOW_ROOT/tools/stow-environment.sh" "$@"

    rm -rf "$STOW_ROOT/_Inline"
    rm -f "$STOW_ROOT/bin/chkstow"
    rm -f "$STOW_ROOT/bin/stow"
    rm -f "$STOW_ROOT/lib/Stow.pm"
    rm -f "$STOW_ROOT/lib/Stow/Util.pm"
    echo "✔ Removed output files."

    local _perl_make_args=()

    if install_perl_dependencies; then
        if activate_local_perl_library; then
            _perl_make_args+=(-I "$STOW_PERL_LOCAL_LIB/lib/perl5" "-Mlocal::lib=""$STOW_PERL_LOCAL_LIB")
        fi
    else
        _return_value=$?
        echo "Failed to install Perl dependencies."
        return $_return_value
    fi

    PMDIR="$STOW_ROOT/lib"

    if ! PERL5LIB=$(
        "$STOW_PERL" -V |
            awk '/@INC:/ {p=1; next} (p==1) {print $1}' |
            sed 's/\\/\//g' |
            grep "$PMDIR" |
            head -n 1
    ); then
        echo "INFO: Target '$PMDIR' is not in standard include so will be inlined."
    fi

    if [ -n "$PERL5LIB" ]; then
        PERL5LIB=$(normalize_path "$PERL5LIB")
        USE_LIB_PMDIR=""
        echo "Module directory is listed in standard @INC, so everything"
        echo "should work fine with no extra effort."
    else
        USE_LIB_PMDIR="use lib \"$PMDIR\";"
        echo "This is *not* in the built-in @INC, so the"
        echo "front-end scripts will have an appropriate \"use lib\""
        echo "line inserted to compensate."
    fi

    edit "$STOW_ROOT/bin/chkstow"
    edit "$STOW_ROOT/bin/stow"
    edit "$STOW_ROOT/lib/Stow.pm"
    edit "$STOW_ROOT/lib/Stow/Util.pm"
    cat "$STOW_ROOT/default-ignore-list" >>"$STOW_ROOT/lib/Stow.pm"

    if [ -x "$(command -v autoreconf)" ]; then
        cd "$STOW_ROOT" || true

        # shellcheck disable=SC2016
        PERL5LIB=$("$STOW_PERL" -le 'print $INC[0]')
        PERL5LIB=$(normalize_path "$PERL5LIB")

        echo "Perl: '$STOW_PERL'"
        echo "Perl Lib: '$PERL5LIB'"
        echo "Site Prefix: '${STOW_SITE_PREFIX:-}'"

        run_command autoreconf --install --verbose
        run_command ./configure --prefix="${STOW_SITE_PREFIX:-}" --with-pmdir="$PERL5LIB"
        run_command make bin/stow bin/chkstow lib/Stow.pm lib/Stow/Util.pm
    fi

    echo "✔ Generated Stow binaries and libraries."

    if run_command "$STOW_PERL" "${_perl_make_args[@]}" \
        -I "$STOW_ROOT/lib" -I "$STOW_ROOT/bin" \
        "$STOW_ROOT/bin/stow" --version; then
        echo "✔ Validated generated 'stow' binary."
    else
        _return_value=$?
        echo "Failed to run generated 'stow' binary."
        return $_return_value
    fi

    # Revert build changes and remove intermediate files
    git -C "$STOW_ROOT" restore aclocal.m4 >/dev/null 2>&1 || true
    rm -f \
        "$STOW_ROOT/nul" "$STOW_ROOT/configure~" \
        "$STOW_ROOT/Build.bat" "$STOW_ROOT/Build" >/dev/null 2>&1 || true
    echo "✔ Removed intermediate output files."

    make_docs
}

make_stow "$@"
