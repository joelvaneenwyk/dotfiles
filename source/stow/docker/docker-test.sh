#!/usr/bin/env bash
#
# Test Stow across multiple Perl versions, by executing the
# Docker image built via docker-build.sh.
#
# Usage: ./docker-test.sh [list | PERL_VERSION]
#
# If the first argument is 'list', list available Perl versions.
# If the first argument is a Perl version, test just that version interactively.
# If no arguments are given test all available Perl versions non-interactively.
#

function run_docker() {
    if [ -t 1 ] && [ ! -f /.dockerenv ]; then
        # stdout is a tty so we can run an interactive instance
        docker run --rm -it "$@"
    else
        docker run --rm "$@"
    fi
}

STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"
STOW_VERSION=$(perl "$STOW_ROOT/tools/get-version")
STOW_DOCKER_ROOT="/stow"
STOW_DOCKER_TESTS="$STOW_DOCKER_ROOT/tools/run-tests.sh"

_test_argument="${1:-}"

if [ -z "$_test_argument" ]; then
    # Normal non-interactive run
    run_docker \
        -v "$STOW_ROOT:$STOW_DOCKER_ROOT" \
        -w "$STOW_DOCKER_ROOT" \
        "stowtest:$STOW_VERSION" \
        "$STOW_DOCKER_TESTS"
elif [ "$_test_argument" == list ]; then
    # List available Perl versions
    run_docker \
        -v "$STOW_ROOT:$STOW_DOCKER_ROOT" \
        -w "$STOW_DOCKER_ROOT" \
        -e LIST_PERL_VERSIONS=1 \
        "stowtest:$STOW_VERSION" \
        "$STOW_DOCKER_TESTS"
else
    # Interactive run for testing / debugging a particular version
    run_docker \
        -v "$STOW_ROOT:$STOW_DOCKER_ROOT" \
        -w "$STOW_DOCKER_ROOT" \
        -e "PERL_VERSION=$_test_argument" \
        "stowtest:$STOW_VERSION" \
        "$STOW_DOCKER_TESTS"
fi
