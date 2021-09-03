@echo off

call "%~dp0clean.bat"

setlocal EnableExtensions EnableDelayedExpansion

if not exist "%MYCELIO_ROOT%" call "%~dp0..\env.bat"
set STOW_ROOT=%MYCELIO_ROOT%\source\stow
set VERSION=2.3.2
set PERL=perl
set PMDIR=%prefix%/perl/site/lib
set USE_LIB_PMDIR=

set _inc=0
for /f "tokens=*" %%a in ('%PERL% -V') do (
    if "!_inc!"=="1" (
        echo %%a | findstr /C:"%PMDIR%" 1>nul

        if not errorlevel 1 (
            set PERL5LIB=%%a
            echo # This is in %PERL%'s built-in @INC, so everything
            echo # should work fine with no extra effort.
            goto:$PMCheckDone
        )
    )
    if "%%a"=="@INC:" (
        set _inc=1
    )
)
:$PMCheckDone

if "!PERL5LIB!"=="" (
    set USE_LIB_PMDIR=use lib "%PMDIR%";
    set PERL5LIB=%PMDIR%
    echo This is *not* in %PERL%'s built-in @INC, so the
    echo front-end scripts will have an appropriate "use lib"
    echo line inserted to compensate.
)

echo.
echo PERL5LIB: '!PERL5LIB!'

call :edit "%STOW_ROOT%\bin\chkstow"
call :edit "%STOW_ROOT%\bin\stow"
call :edit "%STOW_ROOT%\lib\Stow.pm"
call :edit "%STOW_ROOT%\lib\Stow\Util.pm"

exit /b 0

:edit
    set input_file=%~1.in
    set output_file=%~1

    :: This is more explicit and reliable than the config file trick
    set _cmd=perl -p -e "s/\@PERL\@/$ENV{PERL}/g;" -e "s/\@VERSION\@/$ENV{VERSION}/g;" -e "s/\@USE_LIB_PMDIR\@/$ENV{USE_LIB_PMDIR}/g;" "%input_file%"
    echo ##[cmd] %_cmd%
    %_cmd% >"%output_file%"
    echo Generated output: '%output_file%'
exit /b 0
