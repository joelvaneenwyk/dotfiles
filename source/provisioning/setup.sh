#!/bin/bash

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
    . "/etc/os-release"
fi

# Keep track of whether or not XRDP is already installed
_xrdp_installed=0

if [ -x "$(command -v xrdp)" ]; then
    _xrdp_installed=1
fi

if grep </proc/cpuinfo -q "^flags.*\ hypervisor"; then
    if [ "${ID:-}" = "ubuntu" ]; then
        _root="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
        _setup_ubuntu="$_root/ubuntu/${VERSION_ID:-}/install.sh"
        if [ -f "$_setup_ubuntu" ]; then
            sudo bash "$_setup_ubuntu"

            # reconfigure the service
            systemctl daemon-reload
            systemctl start xrdp

            /etc/init.d/xrdp restart

            if [ "$_xrdp_installed" = "1" ]; then
                echo "XRDP install is complete. Please reboot your machine to begin using XRDP."
            fi

            echo "--------------------------------------------------"
            echo "$(hostname):3389"
            echo "$(ip route get 1.2.3.4 | awk '{print $7}'):3389"
        else
            echo "❌ Failed to find setup script: '$_setup_ubuntu'"
        fi
    else
        echo "Setup not supported on operating system: '${ID:-}'"
    fi
else
    echo "Skipped setup as not running in Hyper-V instance."
fi
