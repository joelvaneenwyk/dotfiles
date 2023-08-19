#!/usr/bin/env bash

if [ -x "$(command -v pacman)" ]; then
    pacman -S --quiet --noconfirm --needed \
        texinfo texinfo-tex mingw-w64-x86_64-texlive-core mingw-w64-x86_64-texlive-bin \
        mingw-w64-x86_64-perl mingw-w64-x86_64-ghostscript mingw-w64-x86_64-texlive-plain-generic \
        mingw-w64-x86_64-texlive-fonts-recommended
fi
