#!/usr/bin/env bash

if [ -x "$(command -v pacman)" ]; then
    echo "[mycelio] Initial setup and upgrade of MSYS2."

    if [ ! -f "/etc/passwd" ]; then
        mkpasswd -l -c >"/etc/passwd"
    fi

    if [ ! -f "/etc/group" ]; then
        mkgroup -l -c >"/etc/group"
    fi

    if [ ! -L "/etc/nsswitch.conf" ]; then
        rm -f "/etc/nsswitch.conf"
        ln -s "$MYCELIO_ROOT/source/windows/nsswitch.conf" "/etc/nsswitch.conf"
    fi

    # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
    rm -f /var/lib/pacman/db.lck

    pacman -Syu --quiet --noconfirm

    if [ -f "/etc/pacman.d/gnupg/" ]; then
        rm -rf "/etc/pacman.d/gnupg/"
    fi

    pacman-key --init
    pacman-key --populate msys2

    # Long version of '-Syuu' gets fresh package databases from server and
    # upgrades the packages while allowing downgrades '-uu' as well if needed.
    echo "[mycelio] Running upgrade of all packages. This is expected to shutdown terminal if first run."
    pacman --quiet --sync --refresh -uu --noconfirm
fi

# Note that if this is the first run on MSYS2 it will likely never get here.
echo "[mycelio] Initial setup complete."
