#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

function import_mycelio_library() {
    local root

    root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"

    # shellcheck source=source/shell/main.sh
    source "$root/source/shell/main.sh"

    _setup_environment
}

function setup_perl() {
    import_mycelio_library

    # Perl development dependencies
    run_command_sudo "cpanm.dependencies" cpanm --notest YAML Test::Output CPAN::DistnameInfo

    run_command_sudo "cpanm.perl.critic" cpanm --notest Perl::Critic

    run_command_sudo "cpanm.perl.aio" cpanm --notest ExtUtils::MakeMaker common::sense Canary::Stability
    if [ ! -d "$MYCELIO_TEMP/perl-io-aio" ]; then
        run_command "cpanm.perl.aio" git clone -b main https://github.com/joelvaneenwyk/IO-AIO.git "$MYCELIO_TEMP/perl-io-aio"
    fi
    (
        cd "$MYCELIO_TEMP/perl-io-aio" || true
        PERL_CANARY_STABILITY_NOPROMPT=1 run_command "cpanm.perl.aio" perl Makefile.PL
        run_command "cpanm.perl.aio" make
        run_command_sudo "cpanm.perl.aio" make install
        run_command "cpanm.perl.aio" make test
    )

    run_command_sudo "cpanm.perl.language-server" cpanm --notest Moose AnyEvent AnyEvent::AIO Coro JSON Data::Dump PadWalker Scalar::Util Class::Refresh Compiler::Lexer
    run_command "cpanm.perl.language-server" git clone -b master https://github.com/richterger/Perl-LanguageServer.git "$MYCELIO_TEMP/perl-language-server"
    (
        cd "$MYCELIO_TEMP/perl-language-server" || true
        run_command "cpanm.perl.language-server" perl Makefile.PL
        run_command "cpanm.perl.language-server" make
        run_command_sudo "cpanm.perl.language-server" make install
        run_command "cpanm.perl.language-server" make test
    )
}

setup_perl "$@"
