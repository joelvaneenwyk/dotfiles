#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

export MYCELIO_SCRIPT_NAME="synology_initialize_network_tunnel"

MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"
export MYCELIO_ROOT

source "$MYCELIO_ROOT/source/shell/lib.sh"

initialize_network() {
    echo "Initiated network check: '$(date)'" | tee "$MYCELIO_LOG_PATH"

    if is_synology; then
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
            if sudo insmod "/lib/modules/tun.ko"; then
                echo "Loaded tunnel module." | tee -a "$MYCELIO_LOG_PATH"
            else
                echo "Failed to load tunnel module." | tee -a "$MYCELIO_LOG_PATH"
            fi
        else
            echo "Tunnel module already loaded." | tee -a "$MYCELIO_LOG_PATH"
        fi

        echo "Validated 'tun' status: $(date +"%T")" | tee -a "$MYCELIO_LOG_PATH"
    else
        echo "Skipping tunnel setup. This only works on Synology platform." | tee -a "$MYCELIO_LOG_PATH"
    fi
}

initialize_network
