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

call :SetupStowEnvironment "%~dp0..\" %*
exit /b

::
:: Local functions
::

:SetupStowEnvironment
    setlocal EnableExtensions EnableDelayedExpansion

        set _root=%~dp1
        if not exist "%STOW_ROOT%" goto:$Setup
        if "%~2"=="--refresh" goto:$Setup
        if "%STOW_ENVIRONMENT_INITIALIZED%"=="1" goto:$EnvironmentSetupDone
        goto:$EnvironmentSetupDone

        :$Setup
        set PATH_ORIGINAL=%PATH%
        set STARTING_DIR=%CD%
        set STOW_VERSION=0.0.0
        set STOW_PERL_VERSION=0.0
        set STOW_PERL_UNIX=
        set PERL_SITE_BIN_DIR=
        set PERL_BIN_C_DIR=

        set STOW_ROOT=%_root:~0,-1%
        call :ConvertToUnixyPath "STOW_ROOT_UNIX" "!STOW_ROOT!"

        set STOW_LOCAL_BUILD_ROOT=%USERPROFILE%\.tmp\stow
        set WIN_UNIX_SHELL=!STOW_LOCAL_BUILD_ROOT!\msys64\msys2_shell.cmd
        call :FindTool "WIN_UNIX_SHELL" "msys2_shell"
        call :GetDirectoryPath "WIN_UNIX_DIR" "!WIN_UNIX_SHELL!"
        call :ConvertToUnixyPath "WIN_UNIX_DIR_UNIX" "!WIN_UNIX_DIR!"
        call :ConvertToCygwinPath "STOW_ROOT_MSYS" "!STOW_ROOT!"
        if not exist "!STOW_LOCAL_BUILD_ROOT!" mkdir "!STOW_LOCAL_BUILD_ROOT!"

        set TMPDIR=%STOW_LOCAL_BUILD_ROOT%\temp
        if not exist "%TMPDIR%" mkdir "%TMPDIR%"

        set TEXLIVE_BIN=%STOW_LOCAL_BUILD_ROOT%\texlive\bin\win32
        set TEX=%TEXLIVE_BIN%\tex.exe

        set STOW_HOME=%STOW_LOCAL_BUILD_ROOT%\home
        if not exist "%STOW_HOME%" mkdir "%STOW_HOME%"

        set BASH_EXE=!WIN_UNIX_DIR!\usr\bin\bash.exe
        set BASH="%BASH_EXE%" --noprofile --norc -c

        call :FindTool "STOW_GIT" "git" "!WIN_UNIX_DIR!\usr\bin\git.exe"

        call :FindTool "STOW_PERL" "perl" "!STOW_LOCAL_BUILD_ROOT!\perl\perl\bin\perl.exe"
        if not exist "!STOW_PERL!" (
            echo [ERROR] Perl executable not found.
            set STOW_PERL=
            goto:$InitializeEnvironment
        )

        call :StorePerlOutput "STOW_PERL_VERSION" -e "print substr($^^V, 1)"
        if not "!ERRORLEVEL!"=="0" (
            echo [ERROR] Perl executable invalid: '!STOW_PERL!'
            set STOW_PERL=
            goto:$InitializeEnvironment
        )

        call :GetDirectoryPath "PERL_BIN_DIR" "!STOW_PERL!"
        call :GetDirectoryPath "STOW_PERL_ROOT" "!PERL_BIN_DIR!\..\..\DISTRIBUTIONS.txt"
        call :StorePerlOutput "STOW_PERL_HASH" -MDigest::SHA1"=sha1_hex" -le "print substr^(^(sha1_hex $ARGV[1]^), 0, 8^)" "!STOW_PERL!"

        set STOW_PERL_LOCAL_LIB=!STOW_LOCAL_BUILD_ROOT!\perllib\windows\!STOW_PERL_VERSION!.!STOW_PERL_HASH!
        if not exist "!STOW_PERL_LOCAL_LIB!" mkdir "!STOW_PERL_LOCAL_LIB!"
        call :ConvertToUnixyPath "STOW_PERL_LOCAL_LIB_UNIX" "!STOW_PERL_LOCAL_LIB!"

        set PERL5LIB=!STOW_PERL_LOCAL_LIB_UNIX!/lib
        set PERL_LOCAL_LIB_ROOT=!STOW_PERL_LOCAL_LIB_UNIX!
        set STOW_PERL_ARGS=-I "!STOW_PERL_LOCAL_LIB_UNIX!/lib/perl5"

        set STOW_PERL_INIT=!STOW_PERL_LOCAL_LIB!\init.bat
        if exist "!STOW_PERL_INIT!" del "!STOW_PERL_INIT!"

        "!STOW_PERL!" !STOW_PERL_ARGS! -Mlocal::lib -le 1 > nul 2>&1
        if not "!ERRORLEVEL!"=="0" goto:$PerlLocalLibInitialized
            set "STOW_PERL_ARGS=!STOW_PERL_ARGS! -Mlocal::lib^="!STOW_PERL_LOCAL_LIB_UNIX!""
            echo ##[cmd] "!STOW_PERL!" -Mlocal::lib="!STOW_PERL_LOCAL_LIB_UNIX!"
            "!STOW_PERL!" -Mlocal::lib="!STOW_PERL_LOCAL_LIB_UNIX!" >"!STOW_PERL_INIT!"
        :$PerlLocalLibInitialized

        set PERL_SITE_BIN_DIR=!STOW_PERL_ROOT!\perl\site\bin
        set PERL_BIN_C_DIR=!STOW_PERL_ROOT!\c\bin

        call :ConvertToCygwinPath "STOW_PERL_UNIX" "!STOW_PERL!"
            if not exist "!BASH_EXE!" goto:$StowPerlUnixPathSet
            if not "!STOW_PERL_UNIX!"=="" goto:$StowPerlUnixPathSet
            call :StoreCommandOutput "STOW_PERL_UNIX" !BASH! "command -v perl"4
        :$StowPerlUnixPathSet
        if "!STOW_PERL_UNIX!"=="" set STOW_PERL_UNIX=/bin/perl

        echo ::group::Initialize CPAN
        (
            echo yes && echo. && echo no && echo exit
        ) | "!STOW_PERL!" %STOW_PERL_ARGS% "%STOW_ROOT%\tools\initialize-cpan-config.pl"
        echo ::endgroup::

        :: Get current version of Stow using Perl helper utility
        call :StorePerlOutput "STOW_VERSION" "%STOW_ROOT%\tools\get-version"

        call :StorePerlOutput "PERL_LIB" -MCPAN -e "use Config; print $Config{privlib};"
        if exist "!PERL_LIB!" (
            set "PERL_CPAN_CONFIG=%PERL_LIB%\CPAN\Config.pm"
        )

        set _cpanm=!PERL_BIN_DIR!\cpanm.bat
        if not exist "!_cpanm!" goto:$InitializeEnvironment
        for /f "tokens=* usebackq" %%a in (`!_cpanm! Carp --scandeps --verbose 2^>^&1`) do (
            set "str1=%%a"
            set str2=!str1:Work directory is =!
            if not "x!str2!"=="x!str1!" (
                set _cpanm=!str2!
            )
        )
        call :GetDirectoryPath "PERL_CPANM_CONFIG_DIR" "!_cpanm!/../../"

        :$InitializeEnvironment
            echo ------------------
            echo Stow Root: '!STOW_ROOT!'
            echo Stow Root (unixy): '!STOW_ROOT_MSYS!'
            echo Stow v!STOW_VERSION!
            echo Perl: '!STOW_PERL!'
            echo Perl v!STOW_PERL_VERSION!
            echo Perl Bin: '!PERL_BIN_DIR!'
            echo Perl C Bin: '!PERL_BIN_C_DIR!'
            echo Perl (MSYS): '!STOW_PERL_UNIX!'
            echo Perl CPAN Config: '!PERL_CPAN_CONFIG!'
            echo Perl Local Lib: '!STOW_PERL_LOCAL_LIB_UNIX!'
            if exist "!STOW_PERL_INIT!" echo Perl Init: '!STOW_PERL_INIT!'
            echo MSYS2: '!WIN_UNIX_DIR!'
            echo MSYS2 (unixy): '!WIN_UNIX_DIR_UNIX!'

        if not exist "!WIN_UNIX_DIR!\post-install.bat" goto:$SkipPostInstall
            cd /d "!WIN_UNIX_DIR!"
            call :Run "!WIN_UNIX_DIR!\post-install.bat"
            echo Executed post install script.

        :$SkipPostInstall
        echo ------------------

        :$EnvironmentSetupDone
        if exist "%STOW_PERL_INIT%" call "%STOW_PERL_INIT%"

        set "PATH=%SystemRoot%\System32;!STOW_PERL_LOCAL_LIB!\bin;!PERL_BIN_C_DIR!;!PERL_BIN_DIR!;%PATH%"

        :: Convert to forward slash otherwise it fails on older versions of Perl e.g, 5.14
        set PERL_MB_OPT=%PERL_MB_OPT:\=/%
        set PERL_MM_OPT=%PERL_MM_OPT:\=/%
        set PERL5LIB=%PERL5LIB:\=/%
    endlocal & (
        set "PATH=%PATH%"
        set "PERL5LIB=%PERL5LIB%"
        set "PERL_LOCAL_LIB_ROOT=%PERL_LOCAL_LIB_ROOT%"
        set "PERL_MB_OPT=%PERL_MB_OPT%"
        set "PERL_MM_OPT=%PERL_MM_OPT%"
        set "STOW_GIT=%STOW_GIT%"
        set "STOW_ENVIRONMENT_INITIALIZED=1"
        set "STOW_ROOT=%STOW_ROOT%"
        set "STOW_ROOT_UNIX=%STOW_ROOT_UNIX%"
        set "STOW_LOCAL_BUILD_ROOT=%STOW_LOCAL_BUILD_ROOT%"
        set "STOW_VERSION=%STOW_VERSION%"
        set "STOW_PERL=%STOW_PERL%"
        set "STOW_PERL_VERSION=%STOW_PERL_VERSION%"
        set "STOW_PERL_INIT=%STOW_PERL_INIT%"
        set "STOW_PERL_UNIX=%STOW_PERL_UNIX%"
        set "STOW_PERL_ARGS=%STOW_PERL_ARGS%"
        set "STOW_PERL_LOCAL_LIB=%STOW_PERL_LOCAL_LIB%"
        set "STOW_PERL_LOCAL_LIB_UNIX=%STOW_PERL_LOCAL_LIB_UNIX%"
        set "PERL_BIN_DIR=%PERL_BIN_DIR%"
        set "PERL_BIN_C_DIR=%PERL_BIN_C_DIR%"
        set "PERL_SITE_BIN_DIR=%PERL_SITE_BIN_DIR%"
        set "PERL_LIB=%PERL_LIB%"
        set "PERL_CPAN_CONFIG=%PERL_CPAN_CONFIG%"
        set "PERL_CPANM_CONFIG_DIR=%PERL_CPANM_CONFIG_DIR%"
        set "PERL5LIB=%PERL5LIB%"
        set "STOW_HOME=%STOW_HOME%"
        set "STARTING_DIR=%STARTING_DIR%"
        set "BASH=%BASH%"
        set "BASH_EXE=%BASH_EXE%"
        set "TMPDIR=%TMPDIR%"
        set "WIN_UNIX_DIR=%WIN_UNIX_DIR%"
        set "GUILE_LOAD_PATH=%GUILE_LOAD_PATH%"
        set "GUILE_LOAD_COMPILED_PATH=%GUILE_LOAD_COMPILED_PATH%"
        set "TEXLIVE_BIN=%TEXLIVE_BIN%"
        set "TEX=%TEX%"
    )

    if not exist "%STOW_PERL%" (
        echo [ERROR] Initialization of Stow environment failed. Perl not found.
        exit /b 55
    )
exit /b 0

:GetDirectoryPath
    setlocal EnableDelayedExpansion
        set _output=
        set _output_variable=%~1
        set _input_path=%~2

        if not exist "!_input_path!" goto:$DirectoryResolved
            for %%F in ("%_input_path%") do set _output=%%~dpF
            if not exist "!_output!" set _output=
            if exist "!_output!" set _output=%_output:~0,-1%

        :$DirectoryResolved
    endlocal & (
        set "%_output_variable%=%_output%"
    )
exit /b

:StorePerlOutput
    setlocal EnableDelayedExpansion
        set _output=
        set _output_variable=%~1
        shift

        set "_args=%1"
        shift
        :$GetPerlArgs
            set "_arg=%~1"
            if "!_arg!"=="" goto:$ExecutePerlCommand
            set "_arg=%1"
            set "_args=%_args% !_arg!"
            shift
        goto:$GetPerlArgs
        :$ExecutePerlCommand

        set "_cmd=%STOW_PERL% -I "!STOW_PERL_LOCAL_LIB_UNIX!/lib/perl5" -Mlocal::lib^="%STOW_PERL_LOCAL_LIB_UNIX%""

        if "%GITHUB_ACTIONS%"=="" (
            echo ^=^=----------------------
            echo ## !_cmd! %_args%
            echo ^=^=----------------------
        ) else (
            echo ::group::!_cmd! %_args%
            echo [command]!_cmd! %_args%
        )

        for /f "tokens=* usebackq" %%a in (`!_cmd! %_args%`) do (
            set "_output=%%a"
            goto:$PerlCommandDone
        )

        :$PerlCommandDone
        echo.  ^> Perl output: '!_output!'
        if not "%GITHUB_ACTIONS%"=="" (
            echo ::endgroup::
        )
    endlocal & (
        set "%_output_variable%=%_output%"
    )
exit /b

:StoreCommandOutput
    setlocal EnableDelayedExpansion
        set _output_variable=%~1
        shift

        set _args=
        set "_args=%1"
        shift
        :$GetArgs
            if "%~1"=="" goto:$ExecuteCommand
            set "_args=%_args% %1"
            shift
        goto:$GetArgs
        :$ExecuteCommand

        if "%GITHUB_ACTIONS%"=="" (
            echo ^=^=----------------------
            echo ## !_cmd! %_args%
            echo ^=^=----------------------
        ) else (
            echo ::group::!_cmd! %_args%
            echo [command]!_cmd! %_args%
        )

        for /f "tokens=* usebackq" %%a in (`%_args%`) do (
            set "_output=%%a"
            goto:$CommandDone
        )

        :$CommandDone
        echo.  ^> Command output: '!_output!'
        if not "%GITHUB_ACTIONS%"=="" (
            echo ::endgroup::
        )
    endlocal & (
        set "%_output_variable%=%_output%"
    )
exit /b

:ConvertToUnixyPath
    setlocal EnableDelayedExpansion
        set _outVar=%~1
        set _inPath=%~2
        set _outPath=%_inPath%
        if exist "!_outPath!" set _outPath=!_outPath:\=/!
    endlocal & (
        set "%_outVar%=%_outPath%"
    )
exit /b

:ConvertToCygwinPath
    setlocal EnableDelayedExpansion
        set _outVar=%~1
        set _inPath=%~2
        set _outPath=
        set _cygpath="%WIN_UNIX_DIR%\usr\bin\cygpath.exe"
        if not exist "%_cygpath%" goto:$Done
        for /f "tokens=* usebackq" %%a in (`""%WIN_UNIX_DIR%\usr\bin\cygpath.exe" "%_inPath%""`) do (
            set "_outPath=%%a"
        )
        :$Done
    endlocal & (
        set "%_outVar%=%_outPath%"
    )
exit /b

:Run %*=Command with arguments
    if "%GITHUB_ACTIONS%"=="" (
        echo ^=^=----------------------
        echo ## !_cmd! %_args%
        echo ^=^=----------------------
    ) else (
        echo ::group::!_cmd! %_args%
        echo [command]!_cmd! %_args%
    )
    call %*
exit /b

:RunTaskGroup
    for /F "tokens=*" %%i in ('echo %*') do set _cmd=%%i
    if "%GITHUB_ACTIONS%"=="" (
        echo ^=^=----------------------
        echo ## !_cmd!
        echo ^=^=----------------------
    ) else (
        echo ::group::!_cmd!
        echo [command]!_cmd!
    )

    %*

    if not "%GITHUB_ACTIONS%"=="" (
        echo ::endgroup::
    )
exit /b

:FindTool
    setlocal EnableExtensions EnableDelayedExpansion
        set _output_variable=%~1
        set _file=%~2

        :: If the variable already contains a valid path, then exit early
        set _output=!%_output_variable%!
        if exist "!_output!" goto:$FindToolDone

        set _where=%SystemRoot%\System32\WHERE.exe
        "%_where%" /Q %_file%
        if not "!ERRORLEVEL!"=="0" goto:$FindToolDone
            for /f "tokens=* usebackq" %%a in (`"%_where%" %_file%`) do (
                set _output=%%a
                goto:$FindToolDone
            )

        :$FindToolDone
        if not exist "!_output!" set _output=%~3
        if not exist "!_output!" set _output=
    endlocal & (
        set "%_output_variable%=%_output%"
        if not exist "%_output%" exit /b 1
    )
exit /b
