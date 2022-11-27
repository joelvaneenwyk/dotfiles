#!/usr/bin/env bash

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
export MYCELIO_ROOT

rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-assert"
git clone "https://github.com/ztombol/bats-assert" "${MYCELIO_ROOT}/test/test_helper/bats-assert"
rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-assert/.git/"
rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-assert/test/"

rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-support"
git clone "https://github.com/ztombol/bats-support" "${MYCELIO_ROOT}/test/test_helper/bats-support"
rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-support/.git/"
rm -rf "${MYCELIO_ROOT}/test/test_helper/bats-support/test/"

bats --verbose-run "$MYCELIO_ROOT/test/test_error_handling.bats"
