#!/usr/bin/env bash

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    MYCELIO_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
    export MYCELIO_ROOT

    MYCELIO_TEST_ROOT="$(cd "$(dirname "$(_get_real_path "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
    export MYCELIO_TEST_ROOT

    export MYCELIO_TEST_LINK="$MYCELIO_TEST_ROOT/.tmpln"

    export TEST_MAIN_DIR="${BATS_TEST_DIRNAME}/.."
    export TEST_DEPS_DIR="${TEST_DEPS_DIR-${TEST_MAIN_DIR}/..}"
}
