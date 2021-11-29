#!/bin/sh

use_sudo() {
    if [ -x "$(command -v sudo)" ] && [ ! -x "$(command -v cygpath)" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

if [ -f "/etc/os-release" ]; then
    # shellcheck disable=SC1091
    . "/etc/os-release"
fi

if [ "${ID:-}" = "ubuntu" ]; then
    use_sudo do-release-upgrade -f DistUpgradeViewNonInteractive
else
    echo "Release upgrade not supported on platform: '${ID:-}'"
fi
