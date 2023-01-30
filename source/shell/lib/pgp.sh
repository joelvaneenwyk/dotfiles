#!/bin/sh

generate_gnugp_config() {
    _gnupg_config_root="$1"

    if mkdir -p "$_gnupg_config_root" >/dev/null 2>&1; then
        _gnupg_templates_root="$MYCELIO_ROOT/source/gnupg"

        cp -f "$_gnupg_templates_root/gpg-agent.template.conf" "$_gnupg_config_root/gpg-agent.conf"
        if grep -qEi "(Microsoft|WSL)" /proc/version >/dev/null 2>&1; then
            _pin_entry="$(get_windows_root)/Program Files (x86)/GnuPG/bin/pinentry-basic.exe"
        elif [ -f "/usr/local/bin/pinentry-mac" ]; then
            _pin_entry="/usr/local/bin/pinentry-mac"
        fi

        if [ -f "${_pin_entry:-}" ]; then
            # Must use double quotes and not single quotes here or it fails
            echo "pinentry-program \"$_pin_entry\"" | tee -a "$_gnupg_config_root/gpg-agent.conf"
        elif [ -n "${_pin_entry:-}" ]; then
            log_error "Failed to find pinentry program: '$_pin_entry'"
        fi
        echo "Created config from template: '$_gnupg_config_root/gpg-agent.conf'"

        cp -f "$_gnupg_templates_root/gpg.template.conf" "$_gnupg_config_root/gpg.conf"
        echo "Created config from template: '$_gnupg_config_root/gpg.conf'"

        # Set permissions for GnuGP otherwise we can get permission errors during use. We
        # intentionally set permissions differently for files and directories.
        find "$_gnupg_config_root" -type f -exec chmod 600 {} \;
        find "$_gnupg_config_root" -type d -exec chmod 700 {} \;
    fi
}
