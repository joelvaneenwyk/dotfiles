# Perl Version Detection Syntax Error

## Symptom

```
"C:\Program Files\Git\usr\bin\perl.exe" -e "print substr($^^V, 1)"
syntax error at -e line 1, near "^^"
Execution of -e aborted due to compilation errors.
  > Perl output: ""
```

`STOW_PERL_VERSION` is empty for the rest of the setup.

## Cause

The `$^V` variable (Perl version) is accessed via `$^^V` in the batch file to escape the caret for `cmd.exe` delayed expansion. However, Git for Windows' Perl receives the literal `$^^V` instead of `$^V` because the `StorePerlOutput` function processes the argument through `for /f` which performs an extra layer of expansion.

The issue is in `source/stow/tools/stow-environment.bat` at the `StorePerlOutput` call:

```batch
call :StorePerlOutput "STOW_PERL_VERSION" -e "print substr($^^V, 1)"
```

When this reaches the `for /f ... in ('call !_cmd! !_args!')` inside `StorePerlOutput`, the caret escaping doesn't survive all expansion layers.

## Fix

Replace the Perl one-liner with a form that doesn't require caret escaping:

```batch
call :StorePerlOutput "STOW_PERL_VERSION" -e "print substr($], 0, 4)"
```

Or use `sprintf`:

```batch
call :StorePerlOutput "STOW_PERL_VERSION" -e "printf('%vd', $^V)"
```

Alternatively, use a small Perl script file instead of a `-e` one-liner to avoid shell escaping issues entirely.

## Impact

- `STOW_PERL_VERSION` is empty
- The `perllib` directory path becomes `.da39a3ee` (missing version prefix)
- Downstream version-dependent logic is broken
