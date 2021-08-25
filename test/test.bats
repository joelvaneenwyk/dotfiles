#!/usr/bin/env bats

load test_helper

# Most operating systems have a version of 'realpath' but macOS (and perhaps others) do not
# so we define our own version here.
function _get_real_path() {
    _pwd="$(pwd)"
    _path="$1"
    _offset=""
    _real_path=""

    while :; do
        _base="$(basename "$_path")"

        if ! cd "$(dirname "$_path")"; then
            break
        fi

        _link=$(readlink "$_base") || true
        _path="$(pwd)"

        if [ -n "$_link" ]; then
            if [ -f "$_path" ]; then
                _real_path=$(_get_real_path "$_link")
                break
            else
                _path="$_path/$_link"
            fi
        else
            _offset="/$_base$_offset"
        fi

        if [ "$_path" = "/" ]; then
            _real_path="$_offset"
            break
        else
            _real_path="$_path$_offset"
        fi
    done

    cd "$_pwd" || true
    echo "$_real_path"

    return 0
}

function _test_path {
    assert_equal "$(_get_real_path "$1")" "$(realpath "$1")"
}

@test "stow" {
    "$TEST_MAIN_DIR/source/stow/bin/stow" --version
}

@test "update permissions" {
    "$TEST_MAIN_DIR/source/synology/update-permissions.sh"
}

@test "initialize network tunnel" {
    "$TEST_MAIN_DIR/source/synology/initialize-network-tunnel.sh"
}

@test "cross platform realpath" {
    echo "$MYCELIO_TEST_ROOT"

    rm -rf "$MYCELIO_TEST_ROOT/.tmpsrc"
    mkdir "$MYCELIO_TEST_ROOT/.tmpsrc"
    rm -rf "$MYCELIO_TEST_LINK"
    rm -f "$MYCELIO_TEST_ROOT/file1.txt"

    ln -s "$MYCELIO_TEST_ROOT/.tmpsrc" "$MYCELIO_TEST_LINK"
    touch "$MYCELIO_TEST_LINK/file.txt"
    touch "$MYCELIO_TEST_ROOT/.tmpsrc/file2.txt"
    ln -s "$MYCELIO_TEST_ROOT/.tmpsrc/file2.txt" "$MYCELIO_TEST_ROOT/file1.txt"

    _test_path "$HOME/.config/base16-fzf"
    _test_path "$HOME/.config/base16-fzf/.gitignore"
    _test_path "/bin"
    _test_path "/bin/apt-get"
    #_test_path ""
    #_test_path "file1.txt"
    _test_path "/bin/apt2"
    _test_path "$HOME/.local/bin"
    _test_path ".tmpsrc"
    #_test_path "$MYCELIO_TEST_LINK"
    #_test_path "$MYCELIO_TEST_LINK/file.txt"
    #_test_path "$MYCELIO_TEST_LINK/file2.txt"

    rm -rf "$MYCELIO_TEST_ROOT/.tmpsrc"
    rm -rf "$MYCELIO_TEST_LINK"
    rm -f "$MYCELIO_TEST_ROOT/file1.txt"
}
