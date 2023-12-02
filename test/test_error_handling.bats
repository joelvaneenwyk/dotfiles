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
    invalid_command
    return $?
}

@test "error handling" {
    load test_helper
    _common_setup

    assert_equal "1" "1"

    setup_environment

    if _result=$(run_command "prefix" _cause_error); then
        assert_failure
    else
        assert_equal "$?" "127"
        assert_equal "$_result" $'##[cmd] _cause_error\n[prefix.out] derp'
    fi

    echo "here we go!"
    #run assert_equal "$(run_command "prefix" _cause_error)" "22"

    echo "done"

    return 0
}
