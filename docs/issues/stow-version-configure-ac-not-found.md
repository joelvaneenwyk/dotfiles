# Stow Version Detection Fails (configure.ac Not Found)

## Symptom

```
"C:\Program Files\Git\usr\bin\perl.exe" -I "C:/Users/JoelVanEenwyk/.tmp/stow/perllib/windows/.da39a3ee/lib/perl5" "E:\source\github.com\joelvaneenwyk\dotfiles\source\stow\tools\get-version"

Failed to get Stow version.
Search path: './../configure.ac'
Unable to find 'configure.ac' file: 'No such file or directory'
```

`STOW_VERSION` remains empty, causing `Stow v` (no version) in the environment summary.

## Cause

The `get-version` Perl script resolves its path using `dirname(__FILE__)` and looks for `configure.ac` relative to the script's location:

```perl
my $dirname = dirname(__FILE__);
my $configure = "$dirname/configure.ac";
unless (-e "$configure") {
  $configure = "$dirname/../configure.ac";
}
```

When called through `StorePerlOutput`, the working directory and how `__FILE__` is resolved may differ. The script expects `configure.ac` at either:
- `source/stow/tools/configure.ac` (same directory)
- `source/stow/configure.ac` (parent directory)

The file exists at `source/stow/configure.ac`, but the path resolution fails because `StorePerlOutput` passes the script path as an argument and Perl's `__FILE__` resolves it relative to the current working directory, which may not be `source/stow/tools/`.

Additionally, the script path uses backslashes (`E:\source\...\tools\get-version`) which `File::Basename::dirname` may not handle correctly on MSYS/Git Perl that expects forward slashes.

## Fix

Option A: Pass the stow root as an argument to `get-version`:

```perl
my $dirname = $ARGV[0] || dirname(__FILE__);
```

And call it as:

```batch
call :StorePerlOutput "STOW_VERSION" "%STOW_ROOT%\tools\get-version" "%STOW_ROOT%"
```

Option B: Ensure the working directory is set before calling `get-version`:

```batch
cd /d "%STOW_ROOT%\tools"
call :StorePerlOutput "STOW_VERSION" "%STOW_ROOT%\tools\get-version"
```

Option C: Make `get-version` use `Cwd::abs_path` to resolve the script's real location:

```perl
use Cwd 'abs_path';
use File::Basename;
my $dirname = dirname(abs_path(__FILE__));
```

## Impact

- `STOW_VERSION` is empty
- Template substitutions via `@VERSION@` produce empty strings in generated stow scripts
- The `stow --version` check at the end of `make-stow.bat` reports no version
