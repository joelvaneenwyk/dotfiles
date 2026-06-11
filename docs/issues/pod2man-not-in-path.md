# pod2man Not Found on PATH

## Symptom

```
Can't find C:\Users\JoelVanEenwyk\scoop\apps\perl\current\perl\bin\pod2man.bat on PATH, '.' not in PATH.
Created 'stow.8' with 'pod2man' Perl script.
WARNING: Failed to build Stow for Windows.
```

Despite the "Created" message appearing, the `make-stow.bat` script exits with a non-zero error code, causing the entire Stow build to fail.

## Cause

The `make-stow.bat` script attempts to run `pod2man.bat` to generate man pages. The current logic finds `pod2man.bat` via `where` (scoop's Perl has it), but when executed, Perl reports `'.' not in PATH` — this is a Perl security feature (since Perl 5.26, `.` is removed from `@INC` by default).

The `pod2man.bat` wrapper script from scoop's Perl is trying to locate its companion `.pl` file relative to itself but fails because the current directory isn't in PATH.

Even though the error occurs, the "Created 'stow.8'" message prints unconditionally (outside the conditional block), and the non-zero exit code propagates to the caller.

## Fix

Option A: Run pod2man via Perl directly instead of through the `.bat` wrapper:

```batch
set "_pod2man_pl=%PERL_BIN_DIR%\pod2man"
if exist "!_pod2man_pl!" (
    call :Run "%STOW_PERL%" "!_pod2man_pl!" --name stow --section 8 "%STOW_ROOT%\bin\stow" >"%STOW_ROOT%\doc\stow.8"
)
```

Option B: Make pod2man non-fatal since man pages aren't needed on Windows:

```batch
if not "!_pod2man!"=="" (
    call :Run "!_pod2man!" --name stow --section 8 "%STOW_ROOT%\bin\stow" >"%STOW_ROOT%\doc\stow.8" 2>nul
    if "!ERRORLEVEL!"=="0" (
        echo Created 'stow.8' with 'pod2man' Perl script.
    ) else (
        echo WARNING: pod2man failed, skipping man page generation.
    )
)
```

Option C: Ensure the working directory or PATH includes the Perl bin directory before calling pod2man:

```batch
set "PATH=%PERL_BIN_DIR%;%PATH%"
```

## Impact

- `make-stow.bat` returns a non-zero exit code
- `setup.bat` interprets this as "Failed to build Stow for Windows"
- The entire dotfiles initialization is aborted
