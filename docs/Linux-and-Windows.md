# OS Differences

Good summary of differences: <https://stackoverflow.com/a/10712976>

Cygwin is a library that endeavours to make UNIX programs able to compile and run on Windows systems with minimal or no modifications, and a comprehensive set of packaged UNIX tools and applications compiled with this library. It is almost a complete wrapper around Windows. It includes an X server and an awful lot of the programs that you can expect to find in a Linux distribution. It is great for people who want to learn or use the UNIX command line in Windows.

MSYS is mostly a port of the UNIX tools necessary to build GNU style packages (with a configure etc) on Windows systems with the MinGW compiler. It uses a variant of the Cygwin library modified to sacrifice some compatibility for efficiency, and is more Windows-friendly.

GnuWin32 is simply a port of some of the GNU tools to Windows. Like MSYS, it uses `msvcrt.dll`, as well as an additional library to provide some UNIX compatibility functions. Its main purpose appears to be to allow Windows programs and batch files to use some of the GNU programs and libraries directly.

For the most part, they all provide UNIX programs on Windows, but there are many subtle differences, including:

## Intent

- Cygwin is for people who want to use UNIX on their Windows OS.
- MSYS is for people who want to build Windows programs using the GNU/UNIX build tools. GnuWin32 is a port of individual GNU programs and libraries to Windows.

## Line Endings

Cygwin lets you use CR/LF or LF.
MSYS expects LF line endings.
GnuWin32 programs expect CR/LF line endings.

## Supplied Programs

In particular, Cygwin has a lot more packages, and GnuWin32 doesn't provide any shells.

As for git, it is available with Cygwin - this version can be used in a Windows directory (accessible under `/cygdrive`). Also, as mentioned, there is `msysgit`.
