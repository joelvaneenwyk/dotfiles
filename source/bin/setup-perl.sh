#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

function import_mycelio_library() {
    local root

    root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

    # shellcheck source=source/shell/mycelio.sh
    source "$root/source/shell/mycelio.sh"

    _setup_environment
}

function setup_perl() {
    import_mycelio_library

    # Perl development dependencies
    _run "[cpanm.dependencies]" _sudo cpanm --notest YAML Test::Output CPAN::DistnameInfo

    _run "[cpanm.perl.critic]" _sudo cpanm --notest Perl::Critic

    _run "[cpanm.perl.aio]" _sudo cpanm --notest ExtUtils::MakeMaker common::sense
    _run "[cpanm.perl.aio]" git clone -b main https://github.com/joelvaneenwyk/IO-AIO.git "$MYCELIO_TEMP/perl-io-aio" || true
    (
        cd "$MYCELIO_TEMP/perl-io-aio" || true
        _run "[cpanm.perl.aio]" perl Makefile.PL
        _run "[cpanm.perl.aio]" make
        _run "[cpanm.perl.aio]" _sudo make install
        _run "[cpanm.perl.aio]" make test
    )

    _run "[cpanm.perl.language-server]" _sudo cpanm --notest Moose AnyEvent AnyEvent::AIO Coro JSON Data::Dump PadWalker Scalar::Util Class::Refresh Compiler::Lexer
    _run "[cpanm.perl.language-server]" git clone -b master https://github.com/richterger/Perl-LanguageServer.git "$MYCELIO_TEMP/perl-language-server"
    (
        cd "$MYCELIO_TEMP/perl-language-server" || true
        _run "[cpanm.perl.language-server]" perl Makefile.PL
        _run "[cpanm.perl.language-server]" make
        _run "[cpanm.perl.language-server]" _sudo make install
        _run "[cpanm.perl.language-server]" make test
    )
}

setup_perl "$@"
