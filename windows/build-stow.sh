#!/usr/bin/env bash

#
# This is the set of instructions neede to get `stow` built on Windows using `msys2`
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Script directory: '$SCRIPT_DIR'"
source "$SCRIPT_DIR/../bash/.bashrc"

if tex --version; then
    echo "Found tex."
else
    echo "Failed to find tex."
    exit 1
fi

echo "Downloading minimal packages to build 'stow' on Windows using MSYS2..."
pacman -S --noconfirm make perl autoconf automake1.16 texinfo texinfo-tex

cpan CPAN::DistnameInfo

# This will consistently hangs in MSYS2 (see https://rt-cpan.github.io/Public/Bug/Display/64319/) so we
# just skip it as it's not strictly necessary.
#cpan Test::Output

# Move to source directory and start install.
cd "$SCRIPT_DIR/../stow" || true
autoreconf -iv

# We want a local install
siteprefix=''
./configure --prefix="$siteprefix" && make
