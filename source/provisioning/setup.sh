#!/bin/bash

use_sudo() {
    if [ -x "$(command -v sudo)" ] && [ ! -x "$(command -v cygpath)" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

_dotfiles="$HOME/dotfiles"
_provision="$HOME/dotfiles/source/provisioning/setup.sh"

# Keep track of whether or not XRDP is already installed
if [ -x "$(command -v xrdp)" ]; then
    _xrdp_installed=1
else
    _xrdp_installed=0
fi

if [ -x "$(command -v apt-get)" ]; then
    use_sudo apt-get update
    use_sudo apt-get install -y --no-install-recommends \
        sudo git bash net-tools openssh-server
fi

if [ -x "$(command -v ufw)" ]; then
    use_sudo ufw allow ssh
fi

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

            if [ "$_xrdp_installed" = "0" ]; then
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
