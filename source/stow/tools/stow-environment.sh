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

function normalize_path {
    input_path="${1:-}"

    if [ -n "$input_path" ] && [ -x "$(command -v cygpath)" ]; then
        input_path="$(cygpath "$input_path")"
        if [ -f "${input_path}.exe" ]; then
            input_path="${input_path}.exe"
        fi
    fi

    # shellcheck disable=SC2001
    echo "$input_path" | sed 's:/*$::'

    return 0
}

function resolve_path {
    input_path="$(normalize_path "${1:-}")"
    if [ ! -e "$input_path" ]; then
        input_path=""
    fi
    echo "$input_path"
    return 0
}

function timestamp() {
    echo "##[timestamp] $(date +"%T")"
}

function run_command() {
    local command_display

    command_display="$*"
    command_display=${command_display//$'\n'/} # Remove all newlines

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "[command]$command_display"
    else
        echo "##[cmd] $command_display"
    fi

    "$@"
}

function run_named_command_group() {
    group_name="${1:-}"
    shift

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::group::$group_name"
    else
        echo "==----------------------"
        echo "## $group_name"
        echo "==----------------------"
    fi

    return_code=0
    timestamp
    if run_command "$@"; then
        echo "✔ Command succeeded."
    else
        return_code=$?
        echo "x Command failed, return code: '$return_code'"
    fi

    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::endgroup::"
    fi

    return $return_code
}

function run_command_group() {
    # Remove all newlines from arguments for display group name
    run_named_command_group "${*//$'\n'/}" "$@"
}

function use_sudo {
    if [ -x "$(command -v sudo)" ] && [ ! -x "$(command -v cygpath)" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

function use_perl_local_lib() {
    local _perl_local_args
    _perl_local_args=(-I "$STOW_PERL_LOCAL_LIB/lib/perl5")

    if "$STOW_PERL" "${_perl_local_args[@]}" -Mlocal::lib -le 1 2>/dev/null; then
        # shellcheck disable=SC2054
        _perl_local_args+=("-Mlocal::lib=""$STOW_PERL_LOCAL_LIB")

        #
        # Get the environment setup and convert it to something that works in unix.
        #
        #   1. Convert drive to MSYS e.g., D:\ -> /d/
        #   2. Convert variable references e.g., %MYVAR% -> ${MYVAR}
        #   3. Convert backslashes to forward slashes e.g., ${HOME}\Is\The\Best -> ${HOME}/Is/The/Best
        #
        _perl_local_setup="$(
            COMSPEC="" "$STOW_PERL" "${_perl_local_args[@]}" |
                sed 's#\([a-zA-Z]\):\\#/\1#g' |
                sed 's#\%\([^]]*\)\%#\${\1}#g' |
                perl -pe 's#\\(?!\")#\/#g' |
                sed 's#\/\/#\/#g' |
                sed 's#\/\/#\/#g'
        )"

        echo "$_perl_local_setup"

        return 0
    fi

    return 1
}

function activate_local_perl_library() {
    if _perl_export=$(use_perl_local_lib); then
        echo "Perl: '$STOW_PERL'"
        echo "-------------"
        echo "$_perl_export"
        eval "$_perl_export"

        # Allows tex to be used right after installation
        if [ -f "/usr/libexec/path_helper" ]; then
            eval "$(/usr/libexec/path_helper)"
        fi

        # Need to make sure that latest texinfo and makeinfo are found first as the version
        # that comes with macOS is too old and you will get errors while building docs with
        # errors like 'makeinfo: invalid option -- c'
        PATH="/usr/local/opt/texinfo/bin:/Library/TeX/texbin/:$PERL_BIN:$PERL_C_BIN:$STOW_PERL_LOCAL_LIB/bin:$PATH"
        export PATH
        echo "PATH='$PATH'"

        export PERL_LOCAL_LIB_ROOT="$STOW_PERL_LOCAL_LIB"

        # shellcheck disable=SC2016
        PERL5LIB="$PERL_LOCAL_LIB_ROOT"
        PERL5LIB=$(normalize_path "$PERL5LIB")
        export PERL5LIB

        return 0
    else
        export PATH="$PERL_BIN:$PERL_C_BIN:$STOW_PERL_LOCAL_LIB/bin:$PATH"
    fi

    return 1
}

function install_perl_modules() {
    # Since we call CPAN manually it is not always set, but there are some libraries
    # like IO::Socket::SSL use this to determine whether or not to prompt for next
    # steps e.g., see https://github.com/gbarr/perl-libnet/blob/master/Makefile.PL
    export PERL5_CPAN_IS_RUNNING=1
    export NO_NETWORK_TESTING=1
    export LOCALTESTS_ONLY=1

    _return_value=0
    _use_local_lib=0

    _cpanm_install="$STOW_PERL_LOCAL_LIB/bin/cpanm_install"
    mkdir -p "$STOW_PERL_LOCAL_LIB/bin/"
    if [ ! -f "$_cpanm_install" ]; then
        if [ -x "$(command -v wget)" ] && wget -O "$_cpanm_install" "https://cpanmin.us/"; then
            echo "[wget] Downloaded 'cpanm' installer: '$_cpanm_install'"
        elif [ -x "$(command -v curl)" ] && curl -SLf -o "$_cpanm_install" "https://cpanmin.us/"; then
            echo "[curl] Downloaded 'cpanm' installer: '$_cpanm_install'"
        fi

        if [ -f "$_cpanm_install" ]; then
            chmod +x "$_cpanm_install"
        fi
    fi

    _cpanm=""
    _perl_bin="$(dirname "$STOW_PERL")"
    _cpanm_options=(
        "$_perl_bin/cpanm"
        "$_perl_bin/site_perl/$("$STOW_PERL" -e "print substr($^V, 1)")/cpanm"
        "$_perl_bin/core_perl/cpanm"
        "$STOW_PERL_LOCAL_LIB/bin/cpanm"
    )
    for _cpanm_option in "${_cpanm_options[@]}"; do
        if [ -f "$_cpanm_option" ]; then
            _cpanm="$_cpanm_option"
            break
        fi
    done

    _perl_install_args=("$STOW_PERL")

    while [ -n "${1:-}" ]; do
        package=$1

        if [ "$_use_local_lib" = "0" ] && activate_local_perl_library; then
            _use_local_lib=1
            _perl_install_args+=(-I "$STOW_PERL_LOCAL_LIB/lib/perl5" "-Mlocal::lib=""$STOW_PERL_LOCAL_LIB")
        fi

        if [ "$_use_local_lib" = "1" ] && run_command "${_perl_install_args[@]}" -MApp::cpanminus -le 1 &>/dev/null; then
            if run_command "${_perl_install_args[@]}" -MApp::cpanminus::fatscript -le 1 &>/dev/null; then
                # shellcheck disable=SC2016
                _perl_install_args+=(-MApp::cpanminus::fatscript -le 'my $c = App::cpanminus::script->new; $c->parse_options(@ARGV); $c->doit;' --)
            else
                _perl_install_args=("$STOW_PERL" "$_cpanm")
            fi

            if ! run_named_command_group "Install Module(s): '$*'" \
                "${_perl_install_args[@]}" --local-lib "$STOW_PERL_LOCAL_LIB" --notest "$@"; then
                echo "❌ Failed to install modules with CPANM."
                _return_value=99
            fi

            break
        elif [ "$package" = "App::cpanminus" ] && [ -f "$_cpanm_install" ]; then
            run_command "${_perl_install_args[@]}" "$_cpanm_install" \
                --local-lib "$STOW_PERL_LOCAL_LIB" --notest 'App::cpanminus'
        fi

        if ! "${_perl_install_args[@]}" -M"$package" -le 1 2>/dev/null; then
            if ! run_named_command_group "Install '$package'" \
                "${_perl_install_args[@]}" -MCPAN -e "CPAN::Shell->notest('install', '$package')"; then
                echo "❌ Failed to install '$package' module with CPAN."
                _return_value=88
                break
            fi
        fi

        shift
    done

    unset PERL5_CPAN_IS_RUNNING NO_NETWORK_TESTING LOCALTESTS_ONLY

    return $_return_value
}

# Install everything needed to run 'autoreconf' along with 'make' so
# that we can generate documentation. It is not enough to build and
# run Stow in Perl with full testing dependencies made available.
function install_packages() {
    packages=("$@")

    if [ -x "$(command -v apt-get)" ]; then
        DEBIAN_FRONTEND=noninteractive use_sudo apt-get update \
            --allow-releaseinfo-change
        DEBIAN_FRONTEND=noninteractive use_sudo apt-get -y install \
            --no-install-recommends "${packages[@]}"
    elif [ -x "$(command -v brew)" ]; then
        brew install "${packages[@]}"

        # Needed for tex binaries
        if [ ! -x "$(command -v tex)" ]; then
            brew install --cask basictex
        fi

        # Allows tex to be used right after installation
        if [ -f "/usr/libexec/path_helper" ]; then
            eval "$(/usr/libexec/path_helper)"
        fi

        # Need to make sure that latest texinfo and makeinfo are found first as the version
        # that comes with macOS is too old and you will get errors while building docs with
        # errors like 'makeinfo: invalid option -- c'
        export PATH="/usr/local/opt/texinfo/bin:/Library/TeX/texbin/:$PATH"
        if [ -n "${GITHUB_PATH:-}" ]; then
            # Prepend to path so that next GitHub Action will have this updated path as well
            echo "/usr/local/opt/texinfo/bin" >>"$GITHUB_PATH"
            echo "/Library/TeX/texbin/" >>"$GITHUB_PATH"
        fi
    elif [ -x "$(command -v apk)" ]; then
        use_sudo apk update
        use_sudo apk add "${packages[@]}"
    elif [ -x "$(command -v pacman)" ]; then
        run_named_command_group "Install Packages" pacman \
            -S --quiet --noconfirm --needed "${packages[@]}"
    fi
}

function install_system_dependencies() {
    packages=()

    if [ -x "$(command -v apt-get)" ]; then
        packages+=(
            sudo git bzip2 gawk wget curl patch
            perl libssl-dev openssl libz-dev
            build-essential make autotools-dev automake autoconf
            texlive texinfo
        )
    elif [ -x "$(command -v brew)" ]; then
        packages+=(
            autoconf automake libtool texinfo
        )
    elif [ -x "$(command -v apk)" ]; then
        packages+=(
            sudo wget curl unzip bash xclip git
            build-base gcc g++ make musl-dev openssl openssl-dev zlib-dev
            automake autoconf
            perl perl-dev perl-utils perl-app-cpanminus
            texinfo texlive
        )
    elif [ -x "$(command -v pacman)" ]; then
        if [ ! -x "$(command -v git)" ]; then
            packages+=(git)
        fi

        packages+=(
            base-devel gcc make autoconf automake1.16 automake-wrapper libtool
            perl-devel libcrypt-devel openssl openssl-devel
            texinfo texinfo-tex
        )

        if [ -n "${MSYSTEM:-}" ]; then
            packages+=(
                msys2-keyring msys2-runtime-devel msys2-w32api-headers msys2-w32api-runtime
            )
        fi

        if [ -n "${MINGW_PACKAGE_PREFIX:-}" ]; then
            packages+=(
                "$MINGW_PACKAGE_PREFIX-make"
                "$MINGW_PACKAGE_PREFIX-gcc"
                "$MINGW_PACKAGE_PREFIX-binutils"
                "$MINGW_PACKAGE_PREFIX-openssl"
            )

            if [ ! -x "$(command -v tex)" ]; then
                packages+=(
                    "${MINGW_PACKAGE_PREFIX}-texlive-bin"
                    "${MINGW_PACKAGE_PREFIX}-texlive-core"
                )
            fi
        fi
    fi

    install_packages "${packages[@]}"

    unset STOW_ENVIRONMENT_INITIALIZED
}

function initialize_perl() {
    # We call this again to make sure we have the right version of Perl before
    # updating and installing modules.
    update_stow_environment

    if [ ! -x "$STOW_PERL" ]; then
        echo "Perl install not found."
        return 2
    fi

    if [ -n "${USERPROFILE:-}" ]; then
        _user_profile=$(cygpath "${USERPROFILE}")
        rm -f "$_user_profile/.cpan/CPAN/MyConfig.pm" &>/dev/null
        rm -f "$_user_profile/.cpan-w64/CPAN/MyConfig.pm" &>/dev/null
    fi
    rm -rf "$STOW_LOCAL_BUILD_ROOT/home/.cpan" &>/dev/null
    rm -rf "$STOW_LOCAL_BUILD_ROOT/home/.cpan-w64" &>/dev/null
    rm -rf "$HOME/.cpanm" &>/dev/null

    if "$STOW_PERL" -MCPAN -le 1 2>/dev/null; then
        (
            echo "yes"
            echo ""
            echo "no"
            echo "exit"
        ) | COMSPEC="" run_command_group "$STOW_PERL" "$STOW_ROOT/tools/initialize-cpan-config.pl" || true
    fi

    # Depending on install order it is possible in an MSYS environment to get errors about
    # the 'pl2bat' file being missing. Workaround here is to ensure ExtUtils::MakeMaker is
    # installed and then calling 'pl2bat' to generate it. It should be located under bin
    # folder at '/mingw64/bin/core_perl/pl2bat.bat'
    if [ -n "${MSYSTEM:-}" ]; then
        if [ ! "${MSYSTEM:-}" = "MSYS" ]; then
            export PATH="$PATH:$MSYSTEM_PREFIX/bin:$MSYSTEM_PREFIX/bin/core_perl"
        fi

        # We intentionally use 'which' here as we are on Windows
        # shellcheck disable=SC2230
        if [ -x "$(command -v pl2bat)" ]; then
            pl2bat "$(which pl2bat 2>/dev/null)" 2>/dev/null || true
        fi
    fi
}

function install_perl_dependencies() {
    initialize_perl

    modules=()

    # We intentionally install as little as possible here to support as many system combinations as
    # possible including MSYS, cygwin, Ubuntu, Alpine, etc. The more libraries we add here the more
    # seemingly obscure issues you could run into e.g., missing 'cc1' or 'poll.h' even when they are
    # in fact installed.
    modules=(
        local::lib App::cpanminus
        YAML Carp Scalar::Util IO::Scalar Module::Build
        IO::Socket::SSL Net::SSLeay
        Moose TAP::Harness TAP::Harness::Env
        Test::Harness Test::More Test::Exception Test::Output
        Devel::Cover Devel::Cover::Report::Coveralls
        TAP::Formatter::JUnit
    )

    if [ -n "${MSYSTEM:-}" ]; then
        modules+=(ExtUtils::PL2Bat Inline::C Win32::Mutex)
    fi

    if install_perl_modules "${modules[@]}"; then
        echo "Installed required Perl dependencies."
    else
        echo "Failed to install Perl modules."
        return 88
    fi
}

function _find_local_perl() {
    (
        # We manually try to find the version of Perl installed since it is not necessarily
        # automatically added to the PATH.
        _tool_cache="${RUNNER_TOOL_CACHE:-"/c/hostedtoolcache/windows"}"
        _root=$(normalize_path "$_tool_cache/strawberry-perl")
        echo "$_root"
        if [ -d "$_root" ]; then
            find "$_root" -maxdepth 1 -mindepth 1 -type d | (
                while read -r perl_dir; do
                    for variant in "perl/bin/perl.exe" "x64/perl/bin/perl.exe" "x64/perl/bin/perl"; do
                        _perl_path="$perl_dir/$variant"
                        if [ -e "$_perl_path" ]; then
                            echo "$_perl_path"
                        fi
                    done
                done
            )
        fi

        _where="$(normalize_path "${WINDIR:-}\\system32\\where.exe")"
        if [ -f "$_where" ]; then
            "$_where" perl
        fi

        echo "$STOW_LOCAL_BUILD_ROOT/perl/perl/bin/perl.exe"
    ) | while read -r line; do
        line=$(normalize_path "$line")

        if [ -f "$line" ] && [[ ! "$line" == "${MSYSTEM_PREFIX:-}"* ]] && [[ ! "$line" == /usr/* ]]; then
            echo "$line"
            break
        fi
    done
}

function update_stow_environment() {
    # Clear out TMP as TEMP may come from Windows and we do not want tools confused
    # if they find both.
    unset TMP temp tmp

    export STOW_USE_WINDOWS_TOOLS=0

    local POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -w | --use-windows-tools)
            export STOW_USE_WINDOWS_TOOLS=1
            shift # past argument
            ;;
        -r | --refresh)
            unset STOW_ENVIRONMENT_INITIALIZED
            shift # past argument
            ;;
        -d | --debug)
            set -x
            shift # past argument
            ;;
        *)                     # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift              # past argument
            ;;
        esac
    done

    STOW_ROOT="$(normalize_path "${STOW_ROOT:-$(pwd)}")"
    if [ ! -f "$STOW_ROOT/Build.PL" ]; then
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
    export STOW_ROOT

    # We intentionally favor Windows user profile for MSYS2 over local path
    # since it will be more performant for MSYS2 for temporary files to be
    # outside the root directory of MSYS2.
    _tmp="${USERPROFILE:-${HOME:-}}"
    if [ -n "$_tmp" ]; then
        _tmp="$(normalize_path "$_tmp")/.tmp"
    else
        _tmp=$(normalize_path "${TMPDIR:-/var/tmp}")
    fi
    export STOW_LOCAL_BUILD_ROOT="${_tmp}/stow"
    mkdir -p "$STOW_LOCAL_BUILD_ROOT"

    TEX=$(normalize_path "${TEX:-}")
    PDFTEX=$(normalize_path "${PDFTEX:-}")

    case "$(uname -s)" in
    CYGWIN* | MINGW32* | MSYS* | MINGW*)
        _localTexLive="$STOW_LOCAL_BUILD_ROOT/texlive/bin/win32"
        if [ ! -f "$TEX" ] && [ -f "$_localTexLive/tex.exe" ]; then
            TEX="$_localTexLive/tex.exe"
            PDFTEX="$_localTexLive/pdfetex.exe"
        fi
        ;;
    esac

    if [ "${TEX: -4}" == ".exe" ]; then
        if [ ! "$STOW_USE_WINDOWS_TOOLS" = "1" ]; then
            TEX=""
            PDFTEX=""
        else
            export TEXLIVE_ROOT="$STOW_LOCAL_BUILD_ROOT/texlive"
            export TEXLIVE_INSTALL="$STOW_LOCAL_BUILD_ROOT/texlive"
            export TEXDIR="$STOW_LOCAL_BUILD_ROOT/texlive"
            export TEXLIVE_BIN="$TEXDIR/bin/win32"
            export TEXMFCONFIG="$TEXDIR/texmf-config"
            export TEXMFHOME="$TEXDIR/texmf-local"
            export TEXMFLOCAL="$TEXDIR/texmf-local"
            export TEXMFSYSCONFIG="$TEXDIR/texmf-config"
            export TEXMFSYSVAR="$TEXDIR/texmf-var"
            export TEXMFVAR="$TEXDIR/texmf-var"
            export TEXLIVE_INSTALL_PREFIX="$TEXDIR"
            export TEXLIVE_INSTALL_TEXDIR="$TEXDIR"
            export TEXLIVE_INSTALL_TEXMFCONFIG="$TEXDIR/texmf-config"
            export TEXLIVE_INSTALL_TEXMFHOME="$TEXDIR/texmf-local"
            export TEXLIVE_INSTALL_TEXMFLOCAL="$TEXDIR/texmf-local"
            export TEXLIVE_INSTALL_TEXMFSYSCONFIG="$TEXDIR/texmf-config"
            export TEXLIVE_INSTALL_TEXMFSYSVAR="$TEXDIR/texmf-var"
            export TEXLIVE_INSTALL_TEXMFVAR="$TEXDIR/texmf-var"
        fi
    fi

    if [ ! -f "$TEX" ] && _tex="$(command -v tex 2>/dev/null)"; then
        TEX=$_tex
    fi
    export TEX

    if [ ! -f "$PDFTEX" ] && _pdftex="$(command -v pdfetex 2>/dev/null)"; then
        PDFTEX=$_pdftex
    fi
    export PDFTEX

    # Find the local Windows install if it exists
    PERL_LOCAL="$(_find_local_perl)"
    export PERL_LOCAL

    # Only favor local Perl install if running on CI
    if [ -n "${GITHUB_ACTIONS:-}" ] || [ "$STOW_USE_WINDOWS_TOOLS" = "1" ]; then
        STOW_PERL="$(normalize_path "${PERL_LOCAL:-${STOW_PERL:-${PERL:-}}}")"
    else
        STOW_PERL=""
    fi

    if [ ! -f "$STOW_PERL" ]; then
        # Update version we use after we install in case the default version should be
        # different e.g., we just installed mingw64 version of perl and want to use that.
        if ! STOW_PERL="$(command -v perl)"; then
            STOW_PERL="$(normalize_path "${PERL_LOCAL:-${PERL:-}}")"
            if [ ! -f "$STOW_PERL" ]; then
                if [ -f "${MSYSTEM_PREFIX:-}/bin/perl" ]; then
                    STOW_PERL="${MSYSTEM_PREFIX:-}/bin/perl"
                else
                    STOW_PERL=""
                fi
            fi
        fi
    fi
    STOW_PERL="$(normalize_path "${STOW_PERL}")"
    export STOW_PERL
    export STOW_VERSION="0.0.0"

    # Clear out all Perl variables so that they can be reset
    unset PMDIR PERL PERL5LIB \
        PERL_C_BIN PERL_BIN PERL_BIN_C_DIR PERL_BIN_DIR \
        PERL_LIB PERL_LOCAL_LIB_ROOT PERL_SITE_BIN_DIR \
        PERL_MB_OPT PERL_MM_OPT

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

    export STOW_PERL_LOCAL_LIB=""

    _perl_version="0.0"

    if [ -z "$STOW_PERL" ] || ! _perl_version=$("$STOW_PERL" -e "print substr($^V, 1)"); then
        echo "Failed to find Perl install."
    else
        STOW_PERL_HASH=$(shasum -a 512 "$STOW_PERL" | awk '{split($0,a," "); print a[1]}' | head -c 8)
        export STOW_PERL_HASH

        STOW_PERL_LOCAL_LIB="${STOW_LOCAL_BUILD_ROOT}/perllib/${os_name}/${_perl_version}.${STOW_PERL_HASH}"
        mkdir -p "$STOW_PERL_LOCAL_LIB"
        export STOW_PERL_LOCAL_LIB

        STOW_VERSION="$("$STOW_PERL" "$STOW_ROOT/tools/get-version")"
        export STOW_VERSION

        PERL_LIB="${PERL_LIB:-}"
        PERL_CPAN_CONFIG="${PERL_CPAN_CONFIG:-}"
        if "$STOW_PERL" -MCPAN -le 1 2>/dev/null; then
            # shellcheck disable=SC2016
            PERL_LIB="$("$STOW_PERL" -MCPAN -e 'use Config; print $Config{privlib};')"
            PERL_LIB="$(resolve_path "$PERL_LIB")"
            [[ -z "$PERL_LIB" ]] && PERL_LIB="${HOME:-}"

            # This is the default location where we can expect to find the config. If it
            # exists then we have already been setup.
            PERL_CPAN_CONFIG="$(resolve_path "$PERL_LIB/CPAN/Config.pm")"
        fi
        export PERL_LIB PERL_CPAN_CONFIG

        if [ ! -d "${PMDIR:-}" ]; then
            PMDIR="$(
                "$STOW_PERL" -V |
                    awk '/@INC:/ {p=1; next} (p==1) {print $1}' |
                    sed 's/\\/\//g' |
                    head -n 1
            )"
        fi
        PMDIR=$(resolve_path "$PMDIR")
        export PMDIR

        # Only find a prefix if PMDIR does not exist on its own
        STOW_SITE_PREFIX="${STOW_SITE_PREFIX:-}"
        if [ ! -d "$PMDIR" ]; then
            siteprefix=""
            eval "$("$STOW_PERL" -V:siteprefix)"
            STOW_SITE_PREFIX=$(normalize_path "$siteprefix")
        fi
        export STOW_SITE_PREFIX

        _perl_bin="$(dirname "$STOW_PERL")"
        export PERL_BIN="$_perl_bin"

        while [ ! "$_perl_bin" == "/" ] && [ -d "$_perl_bin/../" ]; do
            _perl_bin=$(cd "$_perl_bin" && cd .. && pwd)

            # We need to check if already at root otherwise we end up with '//' which can take
            # a long time to resolve the file test on some platforms.
            if [ ! "$_perl_bin" = "/" ] && [ -f "$_perl_bin/c/bin/ld.exe" ]; then
                export PERL_C_BIN="$_perl_bin/c/bin"
                break
            fi
        done
    fi

    if [ ! -d "${PERL_C_BIN:-}" ]; then
        if [ -x "$(command -v gcc)" ]; then
            PERL_C_BIN="$(dirname "$(command -v gcc)")"
        else
            PERL_C_BIN="/usr/bin"
        fi
    fi
    export PERL_C_BIN

    PERL="$STOW_PERL"
    export PERL

    TEXLIVE_BIN=""
    if [ -f "$TEX" ]; then
        TEXLIVE_BIN="$(dirname "$TEX")"
    fi

    PATH="${PERL_BIN:-}:${PERL_C_BIN:-}:$TEXLIVE_BIN:$PATH"
    export PATH

    if [ ! "${STOW_ENVIRONMENT_INITIALIZED:-}" == "1" ]; then
        if [ -n "${GITHUB_ACTIONS:-}" ] || [ "$STOW_USE_WINDOWS_TOOLS" = "1" ]; then
            echo "✔ Checked Windows global environment for available tools."
        fi

        echo "--------------------"
        echo "Stow Root: '$STOW_ROOT'"
        echo "Stow Version: 'v$STOW_VERSION'"
        echo "Perl: '$STOW_PERL'"
        echo "Perl Version: 'v$_perl_version'"
        echo "Perl Hash: '$STOW_PERL_HASH'"

        if [ -n "${PERL_LOCAL:-}" ]; then
            echo "Perl Local: '$PERL_LOCAL'"
        fi

        echo "Perl Lib: '$PERL_LIB'"

        echo "Perl Local Lib: '$STOW_PERL_LOCAL_LIB'"
        if use_perl_local_lib &>/dev/null; then
            echo " > Local Perl library is ready for use with 'local::lib' module."
        fi

        echo "Perl Module (PMDIR): '$PMDIR'"
        echo "TeX: '${TEX:-}'"
        echo "--------------------"
        echo "✔ Initialized Stow development environment."

        export STOW_ENVIRONMENT_INITIALIZED="1"
    fi
}

function stow_setup() {
    shopt -s failglob 2>&1 || true

    set -o pipefail >/dev/null 2>&1 || true

    # shellcheck source=tools/make-clean.sh
    bash "$STOW_ROOT/tools/make-clean.sh"

    # shellcheck source=tools/install-dependencies.sh
    bash "$STOW_ROOT/tools/install-dependencies.sh"

    (
        cd "$STOW_ROOT" || true

        # This will create 'configure' script
        run_command autoreconf -iv

        # Run configure to generate 'Makefile' and then run make to create the
        # stow library and binary files e.g., 'stow', 'chkstow', etc.
        run_command ./configure --srcdir="$STOW_ROOT" --with-pmdir="${PMDIR:-}" --prefix="${STOW_SITE_PREFIX:-}"

        run_command make

        # This will create 'Build' or 'Build.bat' depending on platform
        run_command "$STOW_PERL" -I "$STOW_ROOT" -I "$STOW_ROOT/lib" "$STOW_ROOT/Build.PL"

        # shellcheck source=tools/make-stow.sh
        run_command "$STOW_ROOT/tools/make-stow.sh"
    )
}

update_stow_environment "$@"
