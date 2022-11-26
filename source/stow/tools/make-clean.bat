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

call :Clean "%~dp0..\" %*
exit /b

:Clean
    setlocal EnableExtensions EnableDelayedExpansion

    set _root=%~dp1
    call "%_root:~0,-1%\tools\stow-environment.bat"
    if not "%~2"=="--all" goto:$RemoveStandard
        rmdir /q /s "%STOW_LOCAL_BUILD_ROOT%\texlive" > nul 2>&1
        rmdir /q /s "%STOW_LOCAL_BUILD_ROOT%\texlive-install" > nul 2>&1
        echo Removed local 'TexLive' install.

        rmdir /q /s "%STOW_LOCAL_BUILD_ROOT%\perllib" > nul 2>&1
        echo Removed local 'Perl' library folder.

        :: Shut down 'gpg-agent' otherwise some files can't be deleted from 'msys64' folder
        echo Terminate any 'gpg-agent' processes.
        "%SystemRoot%\System32\wbem\wmic.exe" process where "ExecutablePath LIKE '%%gpg-agent.exe%%'" call terminate 2>&1

        :: Shut down 'dirmngr' otherwise some files can't be deleted from 'msys64' folder
        echo Terminate any 'dirmngr' processes.
        "%SystemRoot%\System32\wbem\wmic.exe" process where "ExecutablePath LIKE '%%dirmngr.exe%%'" call terminate 2>&1

        rmdir /q /s "%WIN_UNIX_DIR%" > nul 2>&1
        echo Removed local 'MSYS2' install.

        del "%STOW_ROOT%\test_results*.xml" > nul 2>&1

    :$RemoveStandard
    del "\\?\%STOW_ROOT%\nul" > nul 2>&1
    del "%STOW_ROOT%\texput.log" > nul 2>&1
    del "%STOW_ROOT%\Build" > nul 2>&1
    del "%STOW_ROOT%\Build.bat" > nul 2>&1
    del "%STOW_ROOT%\config.*" > nul 2>&1
    del "%STOW_ROOT%\*.bak" > nul 2>&1
    del "%STOW_ROOT%\*.tmp" > nul 2>&1
    del "%STOW_ROOT%\configure" > nul 2>&1
    del "%STOW_ROOT%\configure~" > nul 2>&1
    del "%STOW_ROOT%\configure.lineno" > nul 2>&1
    del "%STOW_ROOT%\Makefile" > nul 2>&1
    del "%STOW_ROOT%\Makefile.in" > nul 2>&1
    del "%STOW_ROOT%\MYMETA.json" > nul 2>&1
    del "%STOW_ROOT%\MYMETA.yml" > nul 2>&1
    del "%STOW_ROOT%\ChangeLog" > nul 2>&1
    del "%STOW_ROOT%\stow-*.tar.bz2" > nul 2>&1
    del "%STOW_ROOT%\stow-*.tar.gz" > nul 2>&1
    del "%STOW_ROOT%\bin\chkstow" > nul 2>&1
    del "%STOW_ROOT%\bin\stow" > nul 2>&1
    del "%STOW_ROOT%\lib\Stow\Util.pm" > nul 2>&1
    del "%STOW_ROOT%\lib\Stow.pm" > nul 2>&1
    del "%STOW_ROOT%\doc\.dirstamp" > nul 2>&1
    del "%STOW_ROOT%\doc\stamp-vti" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.8" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.aux" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.cp" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.info" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.log" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.toc" > nul 2>&1
    del "%STOW_ROOT%\doc\*.pdf" > nul 2>&1
    del "%STOW_ROOT%\doc\*.dvi" > nul 2>&1
    del "%STOW_ROOT%\doc\version.texi" > nul 2>&1
    del "%STOW_ROOT%\doc\manual-single.html" > nul 2>&1
    del "%STOW_ROOT%\doc\manual.pdf" > nul 2>&1
    del "%STOW_ROOT%\automake\install-sh" > nul 2>&1
    del "%STOW_ROOT%\automake\mdate-sh" > nul 2>&1
    del "%STOW_ROOT%\automake\missing" > nul 2>&1
    del "%STOW_ROOT%\automake\test-driver" > nul 2>&1
    del "%STOW_ROOT%\automake\texinfo.tex" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\.gnupg\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\_build\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\_Inline\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\bin\_Inline\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\tools\_Inline\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\_test\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\autom4te.cache\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\blib\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\doc\manual-split\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\doc\manual.t2d\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\doc\stow.t2p\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\stow\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\cover_db\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\tmp-testing-trees\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\tools\tmp-testing-trees\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\stow-!STOW_VERSION!\" > nul 2>&1

    :: This is where 'cpan' files live when run through MSYS2 so this will force Perl
    :: modules to be reinstalled.
    rmdir /q /s "%STOW_LOCAL_BUILD_ROOT%\home\" > nul 2>&1
    rmdir /q /s "%STOW_LOCAL_BUILD_ROOT%\temp\" > nul 2>&1

    git -C "%STOW_ROOT%" checkout -- "%STOW_ROOT%\aclocal.m4" > nul 2>&1

    echo Removed intermediate Stow files from root: '%STOW_ROOT%'
exit /b 0
