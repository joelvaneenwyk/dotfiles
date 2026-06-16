# Font Download Failure (7-Zip Archive)

## Symptom

```
Target: 'C:\Users\JoelVanEenwyk\.tmp\archives\7z2201-extra.7z.out'
[web.client] Downloading: https://www.7-zip.org/a/7z2201-extra.7z
[http.client.handler] Downloading: https://www.7-zip.org/a/7z2201-extra.7z
Failed to download and install font. Failed to download file: https://www.7-zip.org/a/7z2201-extra.7z
WARNING: Failed to change font to JetBrainsMono NF (it went to JetBrainsMono NF). Changing back...
Updated current console font: 'JetBrainsMono NF'
```

## Cause

The `Initialize-Environment.ps1` script tries to download 7-Zip extra (`7z2201-extra.7z`) from `https://www.7-zip.org/a/7z2201-extra.7z` to extract the JetBrainsMono Nerd Font archive. The download fails, likely due to:

1. **Network/firewall restrictions** blocking the 7-zip.org domain
2. **TLS issues** with the HTTP client handler
3. **The URL is outdated** — 7-Zip may have removed or relocated version 22.01 archives

The font ZIP (`JetBrainsMono.zip`) downloads successfully from GitHub, but the 7z extraction tool needed to process it fails to download.

## Fix

Option A: Use a newer or more reliable 7-Zip download URL. Check https://www.7-zip.org/download.html for the current version and update in `install-dependencies.ps1`:

```powershell
$7zUrl = "https://www.7-zip.org/a/7z2409-extra.7z"  # Update to latest
```

Option B: Use `Expand-Archive` (built-in PowerShell) for ZIP files instead of relying on 7-Zip:

```powershell
Expand-Archive -Path $fontZip -DestinationPath $fontDir
```

Since the font is distributed as a `.zip` (not `.7z`), 7-Zip isn't strictly needed for extraction.

Option C: Pre-install 7-Zip via scoop (which is already set up) and use that binary:

```powershell
$7z = (Get-Command 7z -ErrorAction SilentlyContinue).Source
```

## Impact

- Font installation is incomplete (though the warning suggests it partially succeeded)
- Non-fatal: setup continues after the warning
