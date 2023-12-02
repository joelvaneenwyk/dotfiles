#!/usr/bin/env bash

#
# We intentionally do not use '$HOME' here as this can be run as root but we still
# want logs to go into the home directory where these dot files live.
#

function import_mycelio_library() {
    MYCELIO_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" &>/dev/null && cd ../../ && pwd)"
    export MYCELIO_ROOT

    # shellcheck source=source/shell/main.sh
    source "$MYCELIO_ROOT/source/shell/main.sh"

    use_mycelio_library "$@"
}

function _update_permissions() {
    _target="$1"

    if is_synology; then
        if [ -d "$_target" ]; then
            if sudo chown -R "$(whoami):users" "$_target"; then
                echo "✔ Made '$(whoami)' owner: '$_target'" | tee -a "$MYCELIO_LOG_PATH"
            else
                echo "❌ Unable to change owner: '$_target'" | tee -a "$MYCELIO_LOG_PATH"
            fi

            if sudo chmod -R 777 "$_target"; then
                echo "✔ Set permissions: '$_target'" | tee -a "$MYCELIO_LOG_PATH"
            else
                echo "❌ Unable to updated permissions '$_target'" | tee -a "$MYCELIO_LOG_PATH"
            fi
        else
            echo "Skipped permission update. Target not found: '$_target'" | tee -a "$MYCELIO_LOG_PATH"
        fi
    else
        echo "Skipped permission update. This process only works on Synology." | tee -a "$MYCELIO_LOG_PATH"
    fi
}

function update_permissions() {
    import_mycelio_library "synology_update_permissions"

    _media=/volume1/media

    echo "Initiated permission update: '$(date)'" | tee "$MYCELIO_LOG_PATH"
    _update_permissions "$_media/Downloads/Completed"
    _update_permissions "$_media/Downloads/Incomplete"
    _update_permissions "$_media/Shows"
    _update_permissions "$_media/Movies"
    _update_permissions "$_media/Education"
}

update_permissions
