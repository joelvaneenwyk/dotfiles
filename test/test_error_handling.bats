#!/usr/bin/env bats

teardown_file() {
    :
}

setup_file() {
    load test_helper
    _common_setup
}

function _cause_error() {
    set -e
    echo "derp"
    invalidcommand
    echo "no"
    return 22
}

@test "test error handling" {
    set -x

    _setup_environment
    _setup_error_handling

    echo "here we go!"
    _run "prefix" _cause_error
    echo "done"
    exit 0
}
