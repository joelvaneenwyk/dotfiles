@echo off
::
:: This file is part of GNU Stow.
::
:: GNU Stow is free software: you can redistribute it and/or modify it
:: under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: GNU Stow is distributed in the hope that it will be useful, but
:: WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
:: General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program. If not, see https://www.gnu.org/licenses/.
::

call :StartShell "%~dp0" %*

exit /b

::
:: Local functions
::

:Run %*=Command with arguments
    if "%GITHUB_ACTIONS%"=="" (
        echo ##[cmd] %*
    ) else (
        echo [command]%*
    )
    call %*
exit /b

:StartShell
    setlocal EnableExtensions EnableDelayedExpansion

    set _root=%~dp1
    shift
    call "%_root:~0,-1%\tools\stow-environment.bat"

    :: We use 'minimal' to match what CI uses by default to ensure we have a clean environment
    :: for reproducing issues on CI. You can enable 'inherit' if needed but it tends to just make
    :: debugging more difficult as you get potential binary overlaps.
    set "MSYS2_PATH_TYPE=minimal"

    :: No need to update PATH when using 'minimal' so this is just here for when you want to enable
    :: the 'inherit' mode.
    set "PATH=%TEXLIVE_BIN%;%PERL_BIN_DIR%;%PERL_BIN_C_DIR%;%PATH%"

    set "STOW_PERL=%STOW_PERL_UNIX%"
    set "HOME=%STOW_HOME%"

    if not exist "%WIN_UNIX_DIR%\msys2_shell.cmd" (
        echo ERROR: Missing MSYS2 shell: '%WIN_UNIX_DIR%\msys2_shell.cmd'
        exit /b 5
    )

    :: Let the shell decide which version of TeX to use
    set TEX=
    set STOW_ENVIRONMENT_INITIALIZED=

    set _args=%~1
    shift
    :$GetArguments
        if "%~1"=="" goto:$StartShell
        set _args=!_args! %~1
        shift
    goto:$GetArguments

    :$StartShell
    call :Run "%WIN_UNIX_DIR%\msys2_shell.cmd" -no-start -mingw64 -defterm -shell bash -here -c "bash"
exit /b
