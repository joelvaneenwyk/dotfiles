#!/usr/bin/env bash

#
# This is the set of instructions neede to get 'stow' built on Windows using 'msys2'
#

_dot_windows_script_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Script directory: '$_dot_windows_script_root'"
source "$_dot_windows_script_root/../bash/.bashrc"

echo "Downloading minimal packages to build 'stow' on Windows using MSYS2..."
#pacman -S --noconfirm make perl autoconf automake1.16 texinfo texinfo-tex

#cpan CPAN::DistnameInfo

# This will consistently hangs in MSYS2 (see https://rt-cpan.github.io/Public/Bug/Display/64319/) so we
# just skip it as it's not strictly necessary.
#cpan Test::Output

# Move to source directory and start install.
cd "$_dot_windows_script_root/../stow" || true
autoreconf --install --verbose

# We want a local install
./configure --prefix=""

# Documentation part is expected to fail but we can ignore that
make --keep-going --ignore-errors || true
