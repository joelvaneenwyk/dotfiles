# Windows Platform Differences

> See <https://stackoverflow.com/a/10712976> for a good summary of differences.

**Cygwin** is a library and environment that enables UNIX programs to compile and run on Windows systems with minimal or no modifications. It provides a comprehensive set of UNIX tools and applications, including an X server, and is almost a complete wrapper around Windows. Cygwin is great for people who want to use or learn the UNIX command line in Windows, or need a full POSIX-like environment.

**MSYS** is a lightweight environment mainly intended to provide the UNIX tools necessary to build GNU-style packages (with `configure`, `make`, etc.) on Windows, typically with the MinGW compiler. It uses a variant of the Cygwin library, modified for efficiency and better Windows integration, but sacrifices some compatibility. MSYS is more Windows-friendly and is often used as a build environment rather than a full UNIX shell.

**GnuWin32** is a collection of individual GNU tools ported to Windows. Like MSYS, it uses `msvcrt.dll` and an additional library for UNIX compatibility functions. Its main purpose is to allow Windows programs and batch files to use some GNU programs and libraries directly. GnuWin32 is best for users who just need a few UNIX utilities in their Windows environment, not a full shell or POSIX environment.

For the most part, all three provide UNIX programs on Windows, but there are many subtle differences, including:

## Intent

- **Cygwin**: For people who want to use UNIX on their Windows OS, or need a full POSIX-like environment.
- **MSYS**: For people who want to build Windows programs using GNU/UNIX build tools (with MinGW). Not intended as a full UNIX shell.
- **GnuWin32**: For people who want a few GNU programs and libraries on Windows, not a full environment.

## Line Endings

- **Cygwin**: Supports both CR/LF and LF line endings.
- **MSYS**: Expects LF line endings.
- **GnuWin32**: Expects CR/LF line endings.

## Supplied Programs

- **Cygwin**: Offers a large number of packages, including shells and development tools.
- **MSYS**: Provides a minimal set of tools needed for building software.
- **GnuWin32**: Does not provide any shells; just individual utilities.

## Notes on Git

- Git is available with Cygwin and can be used in Windows directories (accessible under `/cygdrive`).
- There is also `msysgit`, which is a version of Git for Windows based on MSYS.

## Additional Notes

- **Cygwin** is suitable for users who want a full UNIX-like environment on Windows, or need to run complex POSIX software.
- **MSYS** is best for developers who need a minimal UNIX-like environment to build native Windows programs.
- **GnuWin32** is best for users who just want a few UNIX utilities in their Windows PATH.

All three projects are less actively maintained than in the past, and for many use cases, [WSL (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/) is now the preferred way to run Linux tools on Windows.
