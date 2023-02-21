#!/usr/bin/env bash

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
export MYCELIO_ROOT

function clone() {
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1"
    git clone --config core.autocrlf=false "https://github.com/ztombol/$1" "${MYCELIO_ROOT}/test/test_helper/$1"
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1/.git/"
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1/test/"
}

clone "bats-assert"
clone "bats-support"

bats --verbose-run "$MYCELIO_ROOT/test/test_error_handling.bats"
