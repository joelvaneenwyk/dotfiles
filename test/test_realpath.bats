#!/usr/bin/env bats

function _test_path {
    assert_equal "$(_get_real_path "$1")" "$(realpath "$1")"
}

teardown_file() {
    rm -rf "$MYCELIO_TEST_ROOT/.tmpsrc"
    rm -rf "$MYCELIO_TEST_LINK"
    rm -f "$MYCELIO_TEST_ROOT/file1.txt"
}

setup_file() {
    load test_helper
    _common_setup

    teardown
    mkdir "$MYCELIO_TEST_ROOT/.tmpsrc"
    ln -s "$MYCELIO_TEST_ROOT/.tmpsrc" "$MYCELIO_TEST_LINK"
    touch "$MYCELIO_TEST_LINK/file.txt"
    touch "$MYCELIO_TEST_ROOT/.tmpsrc/file2.txt"
    ln -s "$MYCELIO_TEST_ROOT/.tmpsrc/file2.txt" "$MYCELIO_TEST_ROOT/file1.txt"
}

setup() {
    load test_helper
    _common_setup
}

@test "cross platform realpath" {
    _test_path "$HOME/.config/base16-fzf"
    _test_path "$HOME/.config/base16-fzf/.gitignore"
    _test_path "/bin"
    _test_path "/bin/apt-get"
    _test_path "/bin/apt2"
    _test_path "$HOME/.local/bin"
    _test_path ".tmpsrc"

    #_test_path ""
    #_test_path "file1.txt"
    #_test_path "$MYCELIO_TEST_LINK"
    #_test_path "$MYCELIO_TEST_LINK/file.txt"
    #_test_path "$MYCELIO_TEST_LINK/file2.txt"
}
