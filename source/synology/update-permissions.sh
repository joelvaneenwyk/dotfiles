#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

export MYCELIO_SCRIPT_NAME="synology_update_permissions"
export MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"
source "$MYCELIO_ROOT/source/shell/lib.sh"

_media=/volume1/media/Downloads
_media_completed="$_media/Completed"

if is_synology; then
    if [ -d "$_media_completed" ]; then
        if sudo chmod -R 777 "$_media_completed"; then
            echo "Updated permissions for downloads: '$_media_completed'" | tee "$_script_log_path"
        else
            echo "❌ Unable to updated permissions '$_media_completed'" | tee "$_script_log_path"
        fi
    else
        echo "Downloads ('$_media_completed') not found. Skipping permission update." | tee "$_script_log_path"
    fi
else
    echo "Skipped permission update. This process only works on Synology." | tee "$_script_log_path"
fi
