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

function initialize_package_manager() {
    if [ -x "$(command -v pacman)" ]; then
        echo "[stow] Initializing MSYS2 package manager."

        if [ ! -f "/etc/passwd" ]; then
            mkpasswd -l -c >"/etc/passwd"
        fi

        if [ ! -f "/etc/group" ]; then
            mkgroup -l -c >"/etc/group"
        fi

        if [ ! -L "/etc/nsswitch.conf" ]; then
            rm -f "/etc/nsswitch.conf"
            cat >"/etc/nsswitch.conf" <<EOL
passwd: files db
group: files db

db_enum: cache builtin
db_home: env cygwin desc
db_shell: cygwin desc
db_gecos: cygwin desc
EOL
        fi

        # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
        rm -f "/var/lib/pacman/db.lck"

        pacman -Syu --quiet --noconfirm

        if [ -f "/etc/pacman.d/gnupg/" ]; then
            rm -rf "/etc/pacman.d/gnupg/"
        fi

        pacman-key --init
        pacman-key --populate msys2

        # Long version of '-Syuu' gets fresh package databases from server and
        # upgrades the packages while allowing downgrades '-uu' as well if needed.
        echo "[stow] Upgrade of all packages."
        pacman --quiet --sync --refresh -uu --noconfirm
    fi

    # Note that if this is the first run on MSYS2 it will likely never get here.
    echo "[stow] Initialized package manager."
}

function install_dependencies() {
    STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"

    # shellcheck source=tools/stow-environment.sh
    source "$STOW_ROOT/tools/stow-environment.sh" "$@"

    if [ -f '/etc/post-install/09-stow.post' ]; then
        initialize_package_manager
    else
        install_system_dependencies
        install_perl_dependencies
    fi
}

install_dependencies "$@"
