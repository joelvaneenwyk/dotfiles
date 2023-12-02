#!/usr/bin/env bash

_common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    TEST_MAIN_DIR="$(cd "${BATS_TEST_DIRNAME:-}" && cd .. && pwd)"
    TEST_DEPS_DIR="$(cd "${TEST_DEPS_DIR-${TEST_MAIN_DIR}}" && cd .. && pwd)"
    export TEST_MAIN_DIR TEST_DEPS_DIR

    export MYCELIO_ROOT="$TEST_MAIN_DIR"
    export MYCELIO_TEST_ROOT="$BATS_TEST_DIRNAME"
    export MYCELIO_TEST_LINK="$MYCELIO_TEST_ROOT/.tmpln"

    # shellcheck source=source/shell/main.sh
    source "$MYCELIO_ROOT/source/shell/main.sh"

    myc_include_all
}
