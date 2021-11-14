#!/bin/sh

if [ ! -x "$(command -v git)" ]; then
    sudo apt-get update
    sudo apt install git
fi

_dotfiles="$HOME/dotfiles"
_provision="$HOME/dotfiles/source/provisioning/setup.sh"

if [ ! -d "$_dotfiles" ]; then
    git clone "https://github.com/joelvaneenwyk/dotfiles" "$_dotfiles"
fi

if [ ! -f "$_provision" ]; then
    git -C "$_dotfiles" pull
fi

if [ -f "/etc/os-release" ]; then
    # shellcheck disable=SC1091
    source "/etc/os-release"
fi

if grep </proc/cpuinfo -q ^flags.*\ hypervisor; then
    if [ "${ID:-}" = "ubuntu" ]; then
        _root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
        _setup_ubuntu="$_root/ubuntu/${VERSION_ID:-}/install.sh"
        if [ -f "$_setup_ubuntu" ]; then
            "$_setup_ubuntu"
        fi
    fi
fi
