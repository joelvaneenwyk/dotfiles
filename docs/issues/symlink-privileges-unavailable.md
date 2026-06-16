# Symbolic Link Privileges Unavailable

## Symptom

```
Unable to add symbolic link privileges. Please run as administrator.
WARNING: System does not support creating symbolic links.
```

## Cause

Windows requires either:
- **Administrator privileges**, or
- **Developer Mode enabled**, or
- The `SeCreateSymbolicLinkPrivilege` policy assigned to the user

The `Initialize-Environment.ps1` script attempts to grant symbolic link privileges but fails because it's running in a non-elevated terminal.

## Fix

Option A: **Enable Developer Mode** (recommended, no admin needed after initial setup):

1. Open Settings > Update & Security > For developers
2. Enable "Developer Mode"

This grants symlink creation rights to all users without needing elevation.

Option B: **Run setup.bat as Administrator** for the initial setup only.

Option C: **Assign the privilege via Local Security Policy** (one-time admin action):

1. Run `secpol.msc`
2. Navigate to Local Policies > User Rights Assignment
3. Find "Create symbolic links"
4. Add your user account

Option D: **Make the script tolerant of missing symlink support** by falling back to directory junctions (which don't require privileges) or file copies:

```powershell
try {
    New-Item -ItemType SymbolicLink -Path $target -Value $source
} catch {
    # Fallback to junction for directories or copy for files
    if (Test-Path $source -PathType Container) {
        cmd /c mklink /J "$target" "$source"
    } else {
        Copy-Item $source $target
    }
}
```

## Impact

- Non-fatal warning: setup continues
- GNU Stow on Windows may not be able to create symlinks for dotfile management, falling back to copies or failing silently during `stow` operations
