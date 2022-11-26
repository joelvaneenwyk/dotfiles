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

set _pwsh="%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile

call :RunCommand %_pwsh% -Command "Set-ExecutionPolicy RemoteSigned -scope CurrentUser;"
if not "!ERRORLEVEL!"=="0" exit /b !ERRORLEVEL!

call :RunCommand %_pwsh% -File "%~dp0install-dependencies.ps1"
if not "!ERRORLEVEL!"=="0" exit /b !ERRORLEVEL!

rmdir /q /s "%USERPROFILE%\.cpan\CPAN" > nul 2>&1
rmdir /q /s "%USERPROFILE%\.cpan\prefs" > nul 2>&1
rmdir /q /s "%USERPROFILE%\.cpan-w64\CPAN" > nul 2>&1
rmdir /q /s "%USERPROFILE%\.cpan-w64\prefs" > nul 2>&1
echo Removed intermediate CPAN files.

rmdir /q /s "%USERPROFILE%\.cpanm" > nul 2>&1
echo Removed intermediate CPANM files.

call "%~dp0stow-environment.bat" --refresh %*
if not "!ERRORLEVEL!"=="0" exit /b !ERRORLEVEL!

:: First install 'local::lib' and then remaining libraries so that they can all be
:: stored in the local modules path.
call :InstallPerlModules "LWP::Protocol::https" "local::lib" "App::cpanminus"
if not "!ERRORLEVEL!"=="0" exit /b !ERRORLEVEL!

:: Install dependencies. Note that 'Inline::C' requires 'make' and 'gcc' to be installed. It
:: is recommended to install MSYS2 packages for copmiling (e.g. mingw-w64-x86_64-make) but
:: many/most Perl distributions already come with the required tools for compiling.
call :InstallPerlModules ^
    "YAML" "ExtUtils::Config" ^
    "LWP::Protocol::https" "IO::Socket::SSL" "Net::SSLeay" ^
    "Carp" "Module::Build" "Module::Build::Tiny" "IO::Scalar" ^
    "Test::Harness" "Test::Output" "Test::More" "Test::Exception" ^
    "ExtUtils::PL2Bat" "Inline::C" "Win32::Mutex" ^
    "Devel::Cover" "Devel::Cover::Report::Coveralls" ^
    "TAP::Formatter::JUnit"

exit /b

::
:: Local helper functions
::

:InstallPerlModules
    cd /d "!STOW_ROOT!"

    set _cmd_return=0
    set _cmd_base="%STOW_PERL%" -I "%STOW_PERL_LOCAL_LIB_UNIX%/lib/perl5"

    :: Since we call CPAN manually it is not always set, but there are some libraries
    :: like IO::Socket::SSL use this to determine whether or not to prompt for next
    :: steps e.g., see https://github.com/gbarr/perl-libnet/blob/master/Makefile.PL
    set PERL5_CPAN_IS_RUNNING=1
    set NO_NETWORK_TESTING=1

    :$Install
        if "%~1"=="" goto:$Done

        set _cmd=%_cmd_base%
        !_cmd! -Mlocal::lib -le 1 > nul 2>&1
        if "!ERRORLEVEL!"=="0" (
            set _cmd=!_cmd! -Mlocal::lib="%STOW_PERL_LOCAL_LIB_UNIX%"
            if not exist "%STOW_PERL_INIT%" !_cmd! >"%STOW_PERL_INIT%"
        )
        if exist "%STOW_PERL_INIT%" call "%STOW_PERL_INIT%"

        set _cpanm=0
        !_cmd! -MApp::cpanminus -le 1 > nul 2>&1
        if "!ERRORLEVEL!"=="0" set _cpanm=1

        set _modules=%~1
        shift
        if "!_cpanm!"=="0" goto:$UseCpan
        :$GetModulesLoop
            if "%~1"=="" goto:$UseCpanm
            set _modules=!_modules! %~1
            shift
        goto:$GetModulesLoop

        :$UseCpan
            set _cmd=!_cmd! -MCPAN -e "CPAN::Shell->notest('install', '!_modules!')"
            goto:$RunCommand

        :$UseCpanm
            !_cmd! -MApp::cpanminus::fatscript -le 1 > nul 2>&1
            if "!ERRORLEVEL!"=="0" (
                set _cmd=!_cmd! -MApp::cpanminus::fatscript -le
                set _cmd=!_cmd! "my $c = App::cpanminus::script->new; $c->parse_options(@ARGV); $c->doit;" --
            ) else (
                set _cmd=!_cmd! "%PERL_BIN_DIR%\cpanm"
            )
            set _cmd=!_cmd! --local-lib "%STOW_PERL_LOCAL_LIB_UNIX%" --notest
            set _cmd=!_cmd! !_modules!
            goto:$RunCommand

        :$RunCommand
            echo ::group::Install Module(s): '!_modules!'
            echo [command]!_cmd!
            !_cmd!
            set _cmd_return=!ERRORLEVEL!
            echo ::endgroup::

    if "!_cmd_return!"=="0" goto:$Install
    :$Done

    set PERL5_CPAN_IS_RUNNING=
exit /b !_cmd_return!

:RunTaskGroup
    for /F "tokens=*" %%i in ('echo %*') do set _cmd=%%i
    echo ::group::%_cmd%
    echo [command]%_cmd%
    %*
    echo ::endgroup::
exit /b

:RunCommand
    for /F "tokens=*" %%i in ('echo %*') do set _cmd=%%i
    echo [command]%_cmd%
    %*
exit /b
