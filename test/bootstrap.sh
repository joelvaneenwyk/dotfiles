#!/usr/bin/env bash

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd .. && pwd)"
export MYCELIO_ROOT

"$MYCELIO_ROOT/test/bats/bin/bats" --verbose-run "$MYCELIO_ROOT/test/test_error_handling.bats"
