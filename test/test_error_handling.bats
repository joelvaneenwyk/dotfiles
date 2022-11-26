#!/usr/bin/env bats

teardown_file() {
    :
}

setup_file() {
    load test_helper
    _common_setup
}

function _cause_error() {
    echo "derp"
    invalidcommand
    return 22
}

@test "error handling" {
    load test_helper

    run assert_equal "1" "1"

    source "$MYCELIO_ROOT/source/bin/mycelio.sh"

    _setup_environment

    if _result=$(run_command "prefix" _cause_error); then
        assert_failure
    else
        run assert_equal "$_result" "command not found"
        run assert_equal "$?" "127"
    fi

    echo "here we go!"
    #run assert_equal "$(run_command "prefix" _cause_error)" "22"

    echo "done"

    return 0
}
