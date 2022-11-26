#!/bin/sh
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.
#

# Standard safety protocol
set -eu

if [ -n "${BASH_VERSION:-}" ]; then
    echo "Bash v$BASH_VERSION"

    # shellcheck disable=SC3028,SC3054,SC2039
    STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

    # shellcheck source=tools/stow-environment.sh
    . "$STOW_ROOT/tools/stow-environment.sh"

    stow_setup
else
    STOW_ROOT="$(cd -P -- "$(dirname -- "$0")" && pwd)"

    if [ -x "$(command -v apk)" ] && [ ! -x "$(command -v bash)" ]; then
        apk update
        apk add bash
    fi

    bash "$STOW_ROOT/setup.sh"
fi
