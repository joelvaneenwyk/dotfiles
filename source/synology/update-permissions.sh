#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

_log_filename="synology_update_permissions.log"

_script="${BASH_SOURCE[0]}"
_script_path="$(realpath "$_script")"
_script_home="$(cd "$(dirname "$_script_path")" &>/dev/null && cd ../../../ && pwd)"
_home=${_script_home:-/var/services/homes/$(whoami)}
_logs="$_home/.logs"
_health_path="$_logs/$_log_filename.log"
mkdir -p "$_logs"

# We use 'whoami' as $USER is not set for scheduled tasks
echo "User: '$(whoami)'" | tee "$_health_path"
echo "Script: '$_script_path'" | tee "$_health_path"
echo "Home: '$_home'" | tee "$_health_path"
echo "Logs available here: '$_health_path'" | tee "$_health_path"

_media=/volume1/media/Downloads
_media_completed="$_media/Completed"

if uname -a | grep -q "synology"; then
    if [ -d "$_media_completed" ]; then
        if sudo chmod -R 777 "$_media_completed"; then
            echo "Updated permissions for downloads: '$_media_completed'" | tee "$_health_path"
        else
            echo "❌ Unable to updated permissions '$_media_completed'" | tee "$_health_path"
        fi
    else
        echo "Downloads ('$_media_completed') not found. Skipping permission update." | tee "$_health_path"
    fi
else
    echo "Skipped permission update. This process only works on Synology." | tee "$_health_path"
fi
