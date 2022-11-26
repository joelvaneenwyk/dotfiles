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

setlocal EnableExtensions EnableDelayedExpansion

set _return_code=0

call "%~dp0stow-environment.bat" %2 %3 %4 %5 %6 %7 %8 %9
if not "!ERRORLEVEL!"=="0" (
    set _return_code=!ERRORLEVEL!
    echo [ERROR] Environment setup failed.
    goto:$MakeEnd
)

call "%STOW_ROOT%\tools\make-clean.bat"

set USE_LIB_PMDIR=
set PMDIR=%STOW_ROOT%\lib
set PMDIR=%PMDIR:\=/%

set _found=X
echo !STOW_PERL! !PMDIR!
for /f "tokens=* usebackq" %%a in (`!STOW_PERL! -V`) do (
    set "_include=%%a"
    if exist "%%a" (
        echo "!_include!" | "%SystemRoot%\System32\find.exe" /I "!PMDIR!" >nul
        if "!ERRORLEVEL!"=="!_found!" (
            set _found=X
            set "PERL5LIB=!_include!"
            echo Target folder '!PMDIR!' is part of built-in @INC, so everything
            echo should work fine with no extra include statements.
        )
    )
    if [!_include!]==[@INC:] (
        set _found=0
    )
)
:$PerlModuleCheckDone

if not "!PERL5LIB!"=="" goto:$InitializedPerlModuleDir
    set USE_LIB_PMDIR=use lib "%PMDIR%";
    set PERL5LIB=!PMDIR!
    echo Target folder is not part of built-in @INC, so the
    echo front-end scripts will add an appropriate "use lib" line
    echo to compensate.
    echo ----------------------------------------
    echo PERL5LIB: '!PERL5LIB!'
:$InitializedPerlModuleDir

call :ReplaceVariables "%STOW_ROOT%\bin\chkstow"
call :ReplaceVariables "%STOW_ROOT%\bin\stow"
call :ReplaceVariables "%STOW_ROOT%\lib\Stow\Util.pm"
call :ReplaceVariables "%STOW_ROOT%\lib\Stow.pm"

:: Append ignore list to the end of the Stow library
type "%STOW_ROOT%\default-ignore-list" >>"%STOW_ROOT%\lib\Stow.pm"

call :Run "%PERL_BIN_DIR%\pod2man.bat" --name stow --section 8 "%STOW_ROOT%\bin\stow" >"%STOW_ROOT%\doc\stow.8"
if not "!ERRORLEVEL!"=="0" (
    set _return_code=!ERRORLEVEL!
    goto:$MakeEnd
)
echo Created 'stow.8' with 'pod2man' Perl script.

:: Remove all intermediate files before running Stow for the first time
rmdir /q /s "%STOW_ROOT%\_Inline\" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\bin\_Inline\" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\tools\_Inline\" > nul 2>&1

set _cpanm=%PERL_BIN_DIR%\cpanm.bat
if exist "%_cpanm%" (
    cd /d "%STOW_ROOT%"
    call "%PERL_BIN_DIR%\cpanm.bat" --installdeps --notest .
)
if not "!ERRORLEVEL!"=="0" (
    set _return_code=!ERRORLEVEL!
    goto:$MakeEnd
)

:: Make sure that 'stow' was successfully compiled by printing out the version.
cd /d "%STOW_ROOT%"
call :Run "%STOW_PERL%" %STOW_PERL_ARGS% -I "%STOW_ROOT%\lib" "%STOW_ROOT%\bin\stow" --version
if not "!ERRORLEVEL!"=="0" (
    set _return_code=!ERRORLEVEL!
    goto:$MakeEnd
)

call :CreateVersionTexi

:: Generate documentation using 'bash' and associated unix tools which
:: are required due to reliance on autoconf.
call :MakeDocs

:: Exeute 'Build.PL' to generate build scripts: 'Build' and 'Build.bat'
cd /d "%STOW_ROOT%"
call :Run "%STOW_PERL%" %STOW_PERL_ARGS% -I "%STOW_ROOT%\lib" -I "%STOW_ROOT%\bin" "%STOW_ROOT%\Build.PL"
if not "!ERRORLEVEL!"=="0" (
    set _return_code=!ERRORLEVEL!
    goto:$MakeEnd
)

:$MakeEnd
    :: Remove leftover files so that 'Build distcheck' succeeds
    del "%STOW_ROOT%\doc\stow.log" > nul 2>&1
    del "%STOW_ROOT%\doc\texput.log" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\doc\manual.t2d\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\_Inline\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\bin\_Inline\" > nul 2>&1
    rmdir /q /s "%STOW_ROOT%\tools\_Inline\" > nul 2>&1

    :: Restore original directory
    cd /d "%STARTING_DIR%"
exit /b !_return_code!

::
:: Local functions
::

:ReplaceVariables
    setlocal EnableExtensions EnableDelayedExpansion

    set input_file=%~1.in
    set output_file=%~1

    :: This is more explicit and reliable than the config file trick
    set perl_command="%STOW_PERL%" -p
    set perl_command=!perl_command! -e "s/\@PERL\@/$ENV{STOW_PERL_UNIX}/g;"
    set perl_command=!perl_command! -e "s/\@VERSION\@/$ENV{STOW_VERSION}/g;"
    set perl_command=!perl_command! -e "s/\@USE_LIB_PMDIR\@/$ENV{USE_LIB_PMDIR}/g;"
    set perl_command=!perl_command! "%input_file%"

    if "%GITHUB_ACTIONS%"=="" (
        echo ##[cmd] !perl_command!
    ) else (
        echo [command]!perl_command!
    )
    call !perl_command! >"%output_file%"
    echo Generated output: '%output_file%'
exit /b

:MakeDocs
    setlocal EnableExtensions EnableDelayedExpansion

    if exist "%TEXLIVE_BIN%\pdfetex.exe" (
        set TEXMFOUTPUT="doc"
        set TEXINPUTS="%STOW_ROOT%\doc;%STOW_ROOT%;%TEXINPUTS%"
        call :Run "%TEXLIVE_BIN%\pdfetex.exe" -output-directory="%STOW_ROOT%\doc" "%STOW_ROOT%\doc\stow.texi"
        move "%STOW_ROOT%\doc\stow.pdf" "%STOW_ROOT%\doc\manual.pdf"
    )
    del "%STOW_ROOT%\doc\stow.aux" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.cp" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.toc" > nul 2>&1
    del "%STOW_ROOT%\doc\stow.log" > nul 2>&1

    if exist "%STOW_GIT%" (
        "%STOW_GIT%" log --format="format:%%ad  %%aN <%%aE>%%n%%n    * %%w(70,0,4)%%s%%+b%%n" --name-status v2.0.2..HEAD >"%STOW_ROOT%\ChangeLog"
        type "%STOW_ROOT%\doc\ChangeLog.OLD" >>"%STOW_ROOT%\ChangeLog"
        echo Generated ChangeLog using 'git' history: '%STOW_ROOT%\ChangeLog'
    ) else (
        echo WARNING: Skipped log generatation as 'git' not found: '%STOW_GIT%'
    )

    if not exist "%WIN_UNIX_DIR%\usr\bin\bash.exe" (
        echo WARNING: Skipped making documentation. Missing unix tools. Please install dependencies first.
        echo ----------------------------------------
        exit /b 0
    )

    set "MSYSTEM=MSYS"
    set "MSYS2_PATH_TYPE=inherit"
    set "HOME=%STOW_HOME%"
    set "PATH=%PERL_BIN_C_DIR%;%WIN_UNIX_DIR%\usr\bin;%WIN_UNIX_DIR%\bin;%STOW_LOCAL_BUILD_ROOT%\texlive\bin\win32;%WIN_UNIX_DIR%\usr\bin\core_perl;%WIN_UNIX_DIR%\mingw32\bin"

    :: Important that we set both 'Perl' versions here
    set "PERL=%STOW_PERL_UNIX%"
    set "STOW_PERL=%STOW_PERL_UNIX%"

    :: We allow profile to be loaded here because we override the HOME directory
    set BASH="%BASH_EXE%" -c

    cd /d "%STOW_ROOT%"

    call :Run %BASH% "source ./tools/stow-environment.sh && install_system_dependencies"
    if not "!ERRORLEVEL!"=="0" exit /b

    set PERL_INCLUDE=-I %WIN_UNIX_DIR_UNIX%/usr/share/automake-1.16
    set PERL_INCLUDE=!PERL_INCLUDE! -I %WIN_UNIX_DIR_UNIX%/usr/share/autoconf
    set PERL_INCLUDE=!PERL_INCLUDE! -I %WIN_UNIX_DIR_UNIX%/usr/share/texinfo
    set PERL_INCLUDE=!PERL_INCLUDE! -I %WIN_UNIX_DIR_UNIX%/usr/share/texinfo/lib/libintl-perl/lib
    set PERL_INCLUDE=!PERL_INCLUDE! -I %WIN_UNIX_DIR_UNIX%/usr/share/texinfo/lib/Text-Unidecode/lib
    set PERL_INCLUDE=!PERL_INCLUDE! -I %WIN_UNIX_DIR_UNIX%/usr/share/texinfo/lib/Unicode-EastAsianWidth/lib

    :: Use 'stow.texi' to generate 'stow.info'
    if exist "%WIN_UNIX_DIR%\usr\bin\texi2any" (
        call :Run "%WIN_UNIX_DIR%\usr\bin\perl" %PERL_INCLUDE% "%WIN_UNIX_DIR%\usr\bin\texi2any" -I doc\ -o doc\ doc\stow.texi
        echo Generated 'doc\stow.info'
    )

    call :Run %BASH% "autoreconf --install --verbose"
    if not "!ERRORLEVEL!"=="0" exit /b

    call :Run %BASH% "./configure --prefix='' --with-pmdir='%STOW_PERL_LOCAL_LIB_UNIX%'"
    if not "!ERRORLEVEL!"=="0" exit /b

    call :Run %BASH% "make doc/manual-single.html"
    if not "!ERRORLEVEL!"=="0" exit /b

    call :Run %BASH% "make bin/stow bin/chkstow lib/Stow.pm lib/Stow/Util.pm"
    if not "!ERRORLEVEL!"=="0" exit /b

    if not exist "%STOW_ROOT%\doc\manual.pdf" (
        call :Run %BASH% "make doc/manual.pdf"
        if not "!ERRORLEVEL!"=="0" exit /b
    )

    echo ----------------------------------------
exit /b

:CreateVersionTexi
    setlocal EnableExtensions EnableDelayedExpansion

    for /F "skip=1 delims=" %%F in ('
        "%SystemRoot%\System32\wbem\wmic.exe" PATH Win32_LocalTime GET Day^,Month^,Year /FORMAT:TABLE
    ') do (
        for /F "tokens=1-3" %%L in ("%%F") do (
            set CurrentDay=0%%L
            set CurrentMonth=0%%M
            set CurrentYear=%%N
        )
    )
    set CurrentDay=%CurrentDay:~-2%
    set CurrentMonth=%CurrentMonth:~-2%

    if "!CurrentMonth!"=="01" set CurrentMonthName=January
    if "!CurrentMonth!"=="02" set CurrentMonthName=Febuary
    if "!CurrentMonth!"=="03" set CurrentMonthName=March
    if "!CurrentMonth!"=="04" set CurrentMonthName=April
    if "!CurrentMonth!"=="05" set CurrentMonthName=May
    if "!CurrentMonth!"=="06" set CurrentMonthName=June
    if "!CurrentMonth!"=="07" set CurrentMonthName=July
    if "!CurrentMonth!"=="08" set CurrentMonthName=August
    if "!CurrentMonth!"=="09" set CurrentMonthName=September
    if "!CurrentMonth!"=="10" set CurrentMonthName=October
    if "!CurrentMonth!"=="11" set CurrentMonthName=November
    if "!CurrentMonth!"=="12" set CurrentMonthName=December

    set STOW_VERSION_TEXI=%STOW_ROOT%\doc\version.texi
    echo @set UPDATED %CurrentDay% %CurrentMonthName% %CurrentYear% >"%STOW_VERSION_TEXI%"
    echo @set UPDATED-MONTH %CurrentMonthName% %CurrentYear% >>"%STOW_VERSION_TEXI%"
    echo @set EDITION %STOW_VERSION% >>"%STOW_VERSION_TEXI%"
    echo @set VERSION %STOW_VERSION% >>"%STOW_VERSION_TEXI%"
exit /b 0

:Run %*=Command with arguments
    if "%GITHUB_ACTIONS%"=="" (
        echo ^=^=----------------------
        echo ##[cmd] %*
        echo ^=^=----------------------
    ) else (
        echo [command]%*
    )
    call %*
exit /b
