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

STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"

function remove_intermediate_files() {
    if [ "${1:-}" == "--all" ]; then
        rm -rf "${STOW_LOCAL_BUILD_ROOT:?}" >/dev/null 2>&1
        rm -rf "${STOW_LOCAL_BUILD_ROOT:?}/home" >/dev/null 2>&1
        rm -rf "${STOW_LOCAL_BUILD_ROOT:?}/temp" >/dev/null 2>&1
    fi

    rm -rf "$STOW_ROOT/_Inline" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/ldeps" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/doc/doc!manual.t2d" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/doc/manual-split" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/doc/stow.t2d" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/doc/stow.t2p" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/doc/stow.html" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/cover_db" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/tmp-testing-trees" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/.gnupg" >/dev/null 2>&1
    rm -rf "$STOW_ROOT/stow-"* >/dev/null 2>&1
    rm -rf "$STOW_ROOT/Stow-"* >/dev/null 2>&1
    rm -rf "$STOW_ROOT/Stow-"* >/dev/null 2>&1
    rm -rf "$STOW_ROOT/autom4te.cache" >/dev/null 2>&1

    rm -f "$STOW_ROOT/automake/install-sh" >/dev/null 2>&1
    rm -f "$STOW_ROOT/automake/mdate-sh" >/dev/null 2>&1
    rm -f "$STOW_ROOT/automake/missing" >/dev/null 2>&1
    rm -f "$STOW_ROOT/automake/test-driver" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/.dirstamp" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/manual.pdf" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/manual-single.html" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stamp-vti" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.info" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.8" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.log" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.info" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.cp" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.aux" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.pdf" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.dvi" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/stow.toc" >/dev/null 2>&1
    rm -f "$STOW_ROOT/doc/version.texi" >/dev/null 2>&1
    rm -f "$STOW_ROOT/config."* >/dev/null 2>&1
    rm -f "$STOW_ROOT/stow."* >/dev/null 2>&1
    rm -f "$STOW_ROOT/"*.log >/dev/null 2>&1
    rm -f "$STOW_ROOT/Makefile" >/dev/null 2>&1
    rm -f "$STOW_ROOT/Makefile.in" >/dev/null 2>&1
    rm -f "$STOW_ROOT/MYMETA.json" >/dev/null 2>&1
    rm -f "$STOW_ROOT/MYMETA.yml" >/dev/null 2>&1
    rm -f "$STOW_ROOT/.bash_history" >/dev/null 2>&1
    rm -f "$STOW_ROOT/configure" >/dev/null 2>&1
    rm -f "$STOW_ROOT/configure~" >/dev/null 2>&1
    rm -f "$STOW_ROOT/ChangeLog" >/dev/null 2>&1
    rm -f "$STOW_ROOT/Build" >/dev/null 2>&1
    rm -f "$STOW_ROOT/Build.bat" >/dev/null 2>&1
    rm -f "$STOW_ROOT/stow-"* >/dev/null 2>&1
    rm -f "$STOW_ROOT/stow.log" >/dev/null 2>&1
    rm -f "$STOW_ROOT/stow."* >/dev/null 2>&1
    rm -f "$STOW_ROOT/test" >/dev/null 2>&1
    rm -f "$STOW_ROOT/nul"* >/dev/null 2>&1

    git -C "$STOW_ROOT" checkout -- "$STOW_ROOT/aclocal.m4" >/dev/null 2>&1 || true

    echo "✔ Removed intermediate Stow files from root: '$STOW_ROOT'"
}

remove_intermediate_files "$@"
