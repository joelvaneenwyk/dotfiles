#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

_log_filename="synology_initialize_network_tunnel.log"

_script="${BASH_SOURCE[0]}"
_script_path="$(realpath "$_script")"
_script_home="$(cd "$(dirname "$_script_path")" &>/dev/null && cd ../../../ && pwd)"
_home=${_script_home:-/var/services/homes/jvaneenwyk}
_logs="$_home/.logs"
_health_path="$_logs/$_log_filename.log"
mkdir -p "$_logs"

# We use 'whoami' as $USER is not set for scheduled tasks
echo "User: '$(whoami)'" | tee "$_health_path"
echo "Script: '$_script_path'" | tee "$_health_path"
echo "Home: '$_home'" | tee "$_health_path"
echo "Logs available here: '$_health_path'" | tee "$_health_path"

initialize_network() {
    mkdir -p "$_logs"

    if uname -a | grep -q "synology"; then
        # Create the necessary file structure for /dev/net/tun
        if [ ! -c "/dev/net/tun" ]; then
            if [ ! -d "/dev/net" ]; then
                sudo mkdir -m 755 "/dev/net"
            fi
            sudo mknod "/dev/net/tun" c 10 200
            sudo chmod 0755 "/dev/net/tun"
        fi

        # Load the tun module if not already loaded
        if ! lsmod | grep -q "^tun\s"; then
            if insmod "/lib/modules/tun.ko"; then
                echo "Loaded tunnel module."
            else
                echo "Failed to load tunnel module."
            fi
        else
            echo "Tunnel module already loaded."
        fi

        echo "Validated 'tun' status: $(date +"%T")" | tee "$_health_path"
    else
        echo "Skipping tunnel setup. This only works on Synology platform." | tee "$_health_path"
    fi
}

initialize_network
