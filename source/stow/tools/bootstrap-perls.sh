#!/bin/bash
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

# Disable 'unbound variable' errors since 'perlbrew' setup will error
# out if they are enabled.
set +o nounset

# Standard safety protocol.
set -eo pipefail

STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"
PERLBREW_ROOT="${PERLBREW_ROOT:-/usr/local/perlbrew}"

if [ ! -f "$PERLBREW_ROOT/etc/bashrc" ]; then
    PERLBREW_ROOT="$HOME/perl5/perlbrew"
fi

_perlbrew_setup="$PERLBREW_ROOT/etc/bashrc"

if [ -f "$_perlbrew_setup" ]; then
    # Load perlbrew environment
    # shellcheck disable=SC1090
    source "$_perlbrew_setup"
    echo "Initialized 'perlbrew' environment."
else
    echo "ERROR: Failed to find 'perlbrew' setup: '$_perlbrew_setup'"
    return 5
fi

# For each Perl version install required modules.
for p_version in $(perlbrew list | sed 's/ //g' | sed 's/\*//g'); do
    # Switch to it.
    perlbrew use "$p_version"

    # Install the needed modules.
    "$PERLBREW_ROOT/bin/cpanm" --installdeps \
        --notest --with-recommends --with-suggests "$STOW_ROOT"
done

# Cleanup to remove any temporary files.
perlbrew clean
