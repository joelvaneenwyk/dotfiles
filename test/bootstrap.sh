#!/usr/bin/env bash

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
export MYCELIO_ROOT

function clone() {
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1"
    git clone --config core.autocrlf=false "https://github.com/ztombol/$1" "${MYCELIO_ROOT}/test/test_helper/$1"
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1/.git/"
    rm -rf "${MYCELIO_ROOT}/test/test_helper/$1/test/"
}

if [ -d "${HOME:-}" ]; then
    mkdir -p "${HOME}/.tmp"
    rm -rf "${HOME}/.tmp/bats"
    git clone --depth 1 https://github.com/bats-core/bats-core.git "${HOME}/.tmp/bats"
    (
        cd "${HOME}/.tmp/bats"
        mkdir -p "${HOME}/.local"
        ./install.sh "${HOME}/.local"
    )
fi

clone "bats-assert"
clone "bats-file"
clone "bats-support"

"${HOME}/.local/bin/bats" --version
"${HOME}/.local/bin/bats" --verbose-run "$MYCELIO_ROOT/test/test_error_handling.bats"
