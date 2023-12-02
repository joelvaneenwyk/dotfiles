#!/bin/bash

function install_powershell() {
    if [ -x "$(command -v apt-get)" ]; then
        if [ -f "/etc/os-release" ]; then
            # shellcheck disable=SC1091
            source "/etc/os-release"
        fi

        if [ "${ID:-}" = "ubuntu" ]; then
            _packages_production="packages-microsoft-prod.deb"
            _url="https://packages.microsoft.com/config/ubuntu/${VERSION_ID:-0.0}/$_packages_production"

            # Download the Microsoft repository GPG keys
            if run_task "powershell.key.get" get_file "$MYCELIO_TEMP/$_packages_production" "$_url"; then
                # Register the Microsoft repository GPG keys
                run_command_sudo "dpkg.register.microsoft" dpkg -i "$MYCELIO_TEMP/$_packages_production"

                # Update the list of products
                run_command_sudo "apt.update" apt-get update

                # Enable the "universe" repositories
                run_command_sudo "apt.add.repository" add-apt-repository universe || true

                # Install PowerShell
                if
                    DEBIAN_FRONTEND="noninteractive" run_command_sudo "apt.install.powershell" \
                        apt-get install -y --no-install-recommends powershell
                then
                    echo "Installed PowerShell."
                else
                    echo "WARNING: Failed to install PowerShell."
                fi
            fi
        fi
    else
        echo "Skipped PowerShell install "
    fi
}
