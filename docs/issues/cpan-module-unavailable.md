# CPAN Module Not Fully Available

## Symptom

```
::group::Initialize CPAN
WARNING: CPAN module not fully available, skipping CPAN configuration.
::endgroup::
```

CPAN configuration is skipped, so no modules can be installed via CPAN during setup.

## Cause

Git for Windows ships a minimal Perl (`C:\Program Files\Git\usr\bin\perl.exe`) that does not include the full CPAN distribution. Specifically, `CPAN::Author` and other submodules are missing from `@INC`.

The guard in `stow-environment.bat` correctly detects this:

```batch
"!STOW_PERL!" %STOW_PERL_ARGS% -MCPAN -le 1 > nul 2>&1
if errorlevel 1 (
    echo WARNING: CPAN module not fully available, skipping CPAN configuration.
)
```

## Fix

Install a full Perl distribution that includes CPAN. Options:

1. **Strawberry Perl** (recommended for Windows): The `install-dependencies.ps1` script already attempts to download Strawberry Perl portable to `%STOW_LOCAL_BUILD_ROOT%\perl\`. Ensure this runs before `stow-environment.bat` is invoked, or adjust the Perl search order in `FindTool` to prefer the installed Strawberry Perl.

2. **Scoop Perl**: A scoop-installed Perl (`C:\Users\JoelVanEenwyk\scoop\apps\perl\current\perl\bin\perl.exe`) should have full CPAN. Add it to the `FindTool` search paths:

   ```batch
   call :FindTool "STOW_PERL" "perl" "!USER_LOCAL_ROOT!\perl\perl\bin\perl.exe" "!STOW_LOCAL_BUILD_ROOT!\perl\perl\bin\perl.exe" "%USERPROFILE%\scoop\apps\perl\current\perl\bin\perl.exe"
   ```

3. **Accept the limitation**: If you only need `stow` itself (not CPAN-installed modules), the build can proceed without CPAN by relying on `cpanm` from a system Perl.

## Impact

- Cannot install Perl modules via CPAN during initial bootstrap
- `local::lib`, `App::cpanminus`, and other dependencies won't be available until a full Perl is on PATH
