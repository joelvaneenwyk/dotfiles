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

function run_command_output_file() {
    output_file=$1
    shift

    local command_display
    command_display="$*"
    command_display=${command_display//$'\n'/} # Remove all newlines

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "[command]$command_display"
    else
        echo "##[cmd] $command_display"
    fi

    "$@" >"$output_file"
}

function initialize_environment() {
    STOW_ROOT="${STOW_ROOT:-$(pwd)}"

    if [ ! -f "$STOW_ROOT/Build.PL" ]; then
        # If running in a Docker instance, we mount project directory to '/stow'
        if [ -f "/stow/Build.PL" ]; then
            STOW_ROOT="/stow"
        else
            STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"
        fi

        if [ ! -f "$STOW_ROOT/Build.PL" ]; then
            echo "ERROR: Stow source root not found: '$STOW_ROOT'"
            return 2
        fi
    fi

    PERLBREW_ROOT="${PERLBREW_ROOT:-/usr/local/perlbrew}"

    if [ -x "$(command -v perlbrew)" ]; then
        export STOW_PERL=perl

        if [ ! -f "$PERLBREW_ROOT/etc/bashrc" ]; then
            PERLBREW_ROOT="$HOME/perl5/perlbrew"
        fi

        if [ -f "$PERLBREW_ROOT/etc/bashrc" ]; then
            # Load perlbrew environment that we found.
            # shellcheck disable=SC1090,SC1091
            source "$PERLBREW_ROOT/etc/bashrc"
        else
            echo "ERROR: Failed to find perlbrew setup: '$PERLBREW_ROOT/etc/bashrc'"
            return 3
        fi
    fi

    # shellcheck source=tools/stow-environment.sh
    source "$STOW_ROOT/tools/stow-environment.sh" "$@"
}

function exit_handler() {
    _error=$?

    trap - EXIT

    if [ ! "$_error" = "0" ]; then
        cat <<EOF
=================================================
❌ ERROR: Tests failed. Return code: '$_error'
=================================================

NOTE: To run a specific test, type something like:

    perl -Ilib -Ibin -It t/cli_options.t

Code can be edited on the host and will immediately take effect inside
this container.
EOF

        # Launch a bash instance so we can debug failures if we
        # are running in Docker container.
        if [ -f /.dockerenv ] && [ -z "${GITHUB_ACTIONS:-}" ]; then
            bash
        fi
    fi

    exit "$_error"
}

function test_perl_version() {
    _return_value=0
    _starting_directory="$(pwd)"

    # Use the version of Perl passed in if 'perlbrew' is installed
    if [ -x "$(command -v perlbrew)" ]; then
        perlbrew use "$1"
    fi

    # Install Perl dependencies on this particular version of Perl in case
    # that has not been done yet.
    install_perl_dependencies

    _perl_test_args=(-I "$STOW_PERL_LOCAL_LIB/lib/perl5")

    if activate_local_perl_library; then
        _perl_test_args+=("-Mlocal::lib=""$STOW_PERL_LOCAL_LIB")
    fi

    _perl_version="0.0"

    if ! _perl_version=$("$STOW_PERL" -e "print substr($^V, 1)" | sed 's#\.#_#g'); then
        echo "Failed to get Perl version."
        return 55
    fi

    if ! os_name="$(uname -s | sed 's#\.#_#g' | sed 's#-#_#g' | sed 's#/#_#g' | sed 's# #_#g' | awk '{print tolower($0)}')"; then
        os_name="unknown"
    fi

    if [ -f "/.dockerenv" ]; then
        os_name="docker_${os_name}"
    elif grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        os_name="wsl_${os_name}"
    elif [ "$(uname -o 2>&1)" = "Msys" ]; then
        os_name="$(echo "msys_${os_name}" | awk '{print tolower($0)}')"
    fi

    _test_result_output_path="$STOW_ROOT/$(
        echo "test_results_${os_name}_${_perl_version}.xml" | awk '{print tolower($0)}'
    )"

    _env=${GITHUB_ENV:-${STOW_PERL_LOCAL_LIB}/.env}
    _cpanm_root="$HOME/.cpanm/work"
    _env_test_path="$_test_result_output_path"

    if [ -x "$(command -v cygpath)" ]; then
        # https://github.com/msys2/setup-msys2/blob/master/main.js
        _cpanm_root=$(cygpath --windows "$_cpanm_root")
        _env_test_path=$(cygpath --windows "$_env_test_path")
    fi

    _cpanm_logs="$_cpanm_root/**/*.log"

    if [ -n "${MSYSTEM:-}" ]; then
        _cpanm_logs="${_cpanm_logs//\//\\}"
    fi

    echo "STOW_CPAN_LOGS=${_cpanm_logs}" | tee -a "$_env"
    echo "STOW_TEST_RESULTS=${_env_test_path}" | tee -a "$_env"

    echo "✔ Exported paths for GitHub Action jobs."

    # Print first non-blank line of Perl version as it includes details of where it
    # was built e.g., 'x86_64-msys-thread-multi'
    "$STOW_PERL" "${_perl_test_args[@]}" --version | sed -e '/^[ \t]*$/d' -e 's/^[ \t]*//' | head -n 1

    # Remove all intermediate files before we start to ensure a clean test
    run_command_group "$STOW_ROOT/tools/make-clean.sh"

    if cd "$STOW_ROOT"; then
        # Run auto reconfigure ('autoreconf') to generate 'configure' script
        run_command_group autoreconf --install --verbose

        # Run 'configure' to generate Makefile
        run_command_group ./configure --prefix="" --with-pmdir="$STOW_PERL_LOCAL_LIB"

        run_command_group make

        # shellcheck disable=SC2016
        if run_command_output_file "$_test_result_output_path" \
            "$STOW_PERL" "${_perl_test_args[@]}" -MApp::Prove \
            -le 'my $c = App::Prove->new; $c->process_args(@ARGV); $c->run;' -- \
            --formatter "TAP::Formatter::JUnit" \
            --norc --timer --verbose --normalize --parse \
            -I "$STOW_PERL_LOCAL_LIB/lib/perl5" \
            -I t/ -I lib/ -I bin/ \
            "$STOW_ROOT/t"; then
            # If file is empty, tests failed so report an error
            if [ ! -s "$_test_result_output_path" ]; then
                echo "❌ Tests failed. Test result file empty: '$_test_result_output_path"
                _return_value=77
            else
                echo "✔ Generated test results: '$_test_result_output_path'"

                # Reset to default Perl install
                unset PERL5LIB PERL_MB_OPT PERL_MM_OPT PERL_LOCAL_LIB_ROOT

                # Remove the local library path
                _local_bin="$STOW_PERL_LOCAL_LIB/bin"
                PATH=":$PATH:"
                PATH="${PATH//:$_local_bin:/:}"
                PATH="${PATH#:}"
                PATH="${PATH%:}"
                export PATH

                export PERL="$STOW_PERL"

                run_command_group make cpanm

                rm -f "$STOW_ROOT/Build" "$STOW_ROOT/Build.bat" >/dev/null 2>&1

                # Ignore line that contains 'Unsuccessful stat on filename' as the error is sometimes not avoidable depending
                # on files in the project folder.
                run_command_group "$PERL" "${_perl_test_args[@]}" Build.PL 2>&1 | "$PERL" -ne 'print unless /Unsuccessful stat on filename/'
                run_command_group ./Build build
                run_command_group ./Build distcheck

                if [ -f "$STOW_PERL_LOCAL_LIB/bin/cover" ]; then
                    _cover="$STOW_PERL_LOCAL_LIB/bin/cover"
                else
                    _cover="$(command -v cover)"
                fi

                if [ -f "$_cover" ]; then
                    if [ -z "${GITHUB_ENV:-}" ]; then
                        run_command_group "$STOW_PERL" "${_perl_test_args[@]}" "$_cover" -test
                    else
                        run_command_group "$STOW_PERL" "${_perl_test_args[@]}" "$_cover" -test -report coveralls
                    fi
                else
                    echo "Failed to run cover. Missing binary: '$_cover'"
                fi

                run_command_group make distcheck
            fi
        else
            _return_value=$?
            echo "❌ Tests failed. Test result file empty: '$_test_result_output_path"
        fi

        cd "$_starting_directory" || true
    fi

    return $_return_value
}

function run_stow_tests() {
    initialize_environment "$@"

    # Standard safety protocol but do this after we setup perlbrew otherwise
    # we get errors with unbound variables
    set -euo pipefail
    shopt -s inherit_errexit nullglob >/dev/null 2>&1 || true
    trap exit_handler EXIT

    _test_argument="${1:-}"

    LIST_PERL_VERSIONS=0
    PERL_VERSION=""

    if [ -x "$(command -v perlbrew)" ]; then
        STOW_PERL=perl
    else
        STOW_PERL="${STOW_PERL:-${PERL:-perl}}"
    fi
    export STOW_PERL

    if [ "$_test_argument" == "list" ]; then
        # List available Perl versions
        LIST_PERL_VERSIONS=1
    elif [ -n "$_test_argument" ]; then
        # Interactive run for testing / debugging a particular version
        PERL_VERSION="$_test_argument"
    fi

    if [ ! "$LIST_PERL_VERSIONS" == "1" ] && [ ! "$_test_argument" == "--no-install" ]; then
        if ! install_system_dependencies; then
            echo "Failed to install dependencies."
            return 4
        fi
    fi

    if [ "$LIST_PERL_VERSIONS" == "1" ]; then
        echo "Listing Perl versions available from perlbrew ..."
        perlbrew list
    elif [ -z "$PERL_VERSION" ] && [ -x "$(command -v perlbrew)" ]; then
        echo "Testing all Perl versions"

        for input_perl_version in $(perlbrew list | sed 's/ //g' | sed 's/\*//g'); do
            test_perl_version "$input_perl_version"
        done

        if [ -z "${GITHUB_ENV:-}" ]; then
            run_command_group make distclean
        fi
    else
        # Test a specific version requested via $PERL_VERSION environment
        # variable.  Make sure set -e doesn't cause us to bail on failure
        # before we start an interactive shell.
        test_perl_version "$PERL_VERSION"

        # We intentionally do not 'make distclean' since we probably want to
        # debug this Perl version interactively.
    fi

    echo "✔ Tests succeeded."
}

run_stow_tests "$@"
