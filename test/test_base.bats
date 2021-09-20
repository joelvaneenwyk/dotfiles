#!/usr/bin/env bats

teardown_file() {
    :
}

setup_file() {
    load test_helper
    _common_setup
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
