#!/usr/bin/env bash

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#

_dot_windows_script_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "[stow] Script directory: '$_dot_windows_script_root'"
source "$_dot_windows_script_root/../bash/.bashrc"

if command -v pacman >/dev/null 2>&1; then
    echo "[stow] Downloading minimal packages to build 'stow' on Windows using MSYS2..."
    pacman -S --noconfirm --needed make perl autoconf automake1.16 git 2>&1 | awk '{ print "[stow.pacman]", $0 }'
else
    echo "[stow] WARNING: Package manager 'pacman' not found. There will likely be missing dependencies."
fi

# Install '-i' but skip tests '-T' for the modules we need. We skip tests in part because
# it is faster but also because tests in 'Test::Output' causes consistent hangs
# in MSYS2, see https://rt-cpan.github.io/Public/Bug/Display/64319/
cpan -i -T YAML Test::Output CPAN::DistnameInfo 2>&1 | awk '{ print "[stow.cpan]", $0 }'

# Move to source directory and start install.
cd "$_dot_windows_script_root/../stow" || true
autoreconf --install --verbose 2>&1 | awk '{ print "[stow.autoreconf]", $0 }'

# We want a local install
./configure --prefix="" 2>&1 | awk '{ print "[stow.configure]", $0 }'

# Documentation part is expected to fail but we can ignore that
make --keep-going --ignore-errors 2>&1 | awk '{ print "[stow.make]", $0 }'

rm -f "./configure~"
git checkout -- "./aclocal.m4" || true
