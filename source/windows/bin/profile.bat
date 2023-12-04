@echo off
goto:$Main
REM
REM This is used as an auto-run script and invoked for every new instance of 'cmd.exe' starts. This script
REM is also invoked when running e.g. 'for /f %%l in ('some command') do ...'
REM
REM In those cases we do not want to run the initialization as it can haveunexpected side effects on the parent
REM script variables. This severly affects the performance of scripts that heavily use for loops.
REM
REM The command for running a new cmd instance is available in the "Command Prompt.lnk" shortcut and would be
REM feasible to extract it from there using JScript WshShell.Createshortcut() and then compare it to %CMDCMDLINE% variable
REM but the performance penalty each time a cmd.exe starts would not be acceptable unless we do it only once
REM at install time.
REM
REM Workaround used here is that we check that a full quoted COMSPEC was used and _not_ using '/c' argument
REM
REM IMPORTANT: Do **not** use %CMDCMDLINE% as is may contain unprotected | & > < characters. Use !CMDCMDLINE! instead.
REM

::-----------------------------------
:: Extract the ARG0 and ARG1 from %CMDCMDLINE% using cmd.exe own parser
::-----------------------------------
:SplitArgs
    set "ARG0=%1"
    set "ARG1=%2"
exit /b

::-----------------------------------
:: Find the root of Mycelio profile and return it
::-----------------------------------
:GetRoot
    if exist "%MYCELIO_ROOT%\setup.bat" exit /b 0
    if "%MYCELIO_ROOT%"=="" (
        set "MYCELIO_ROOT=%~dp1"
        goto:$UpdateRoot
    )

    :$UpdateRoot
    if "!MYCELIO_ROOT:~-1!"=="\" set "MYCELIO_ROOT=!MYCELIO_ROOT:~0,-1!"
    set "ARG1=%2"
exit /b

::-----------------------------------
:: Clear the error level to zero
::-----------------------------------
:ClearErrorLevel
exit /b 0

::-----------------------------------
:: Find and initialize environment variables needed by Mycelio dotfiles
::-----------------------------------
:GetProfileSettings
    setlocal EnableExtensions EnableDelayedExpansion
    set MYCELIO_SKIP_INIT=0

    :: Change 'REM' to 'echo' to get output
    set ECHO=echo

    if "%~1"=="--refresh" goto:$InitializeProfile

    set "CMD=!CMDCMDLINE!"
    set "CMD=!CMD:|=\x7C!"
    set "CMD=!CMD:>=\x3E!"
    set "CMD=!CMD:<=\x3C!"
    set "CMD=!CMD:&=\x36!"

    call :SplitArgs !CMD!

    :: for /f invokes %COMSPEC% without quotes, whereas new shells' ARG0 have quotes. If
    :: ARG0 equals COMSPEC then this is not a new top 'cmd.exe' instance.
    if "!ARG0!"=="%COMSPEC%" goto:$SkipInit

    :: This is not a new top cmd.exe instance
    if /i "!ARG1!"=="/c" goto:$SkipInit

    ::
    :: This is a new top 'cmd.exe' instance so initialize it.
    ::
    if "%MYCELIO_AUTORUN_INITIALIZED%"=="1" goto:$SkipInit
    if "%MYCELIO_PROFILE_INITIALIZED%"=="1" goto:$SkipInit
    goto:$InitializeProfile

    :$SkipInit
    set MYCELIO_SKIP_INIT=1
    set ECHO=REM

    :$InitializeProfile
    call :GetRoot "%~dp0..\..\..\" "%~dpnx0"

    :: Generate and run the environment batch script
    set "MYCELIO_ENV_PATH=%~dp0env.bat"
    if not exist "!_env!" (
        set "MYCELIO_ENV_PATH=!MYCELIO_ROOT!\source\windows\bin\env.bat"
    )
    endlocal & (
        set "MYCELIO_ROOT=%MYCELIO_ROOT%"
        set "MYCELIO_ENV_PATH=%MYCELIO_ENV_PATH%"
        set "MYCELIO_PROFILE_INITIALIZED=1"
        set "MYCELIO_AUTORUN_INITIALIZED=1"
        set "MYCELIO_SKIP_INIT=%MYCELIO_SKIP_INIT%"
        set "MYCELIO_ECHO=%ECHO%"
    )
exit /b

::-----------------------------------
:: Main entrypoint that we jump to at the start.
::-----------------------------------
:$Main
    call :ClearErrorLevel
    call :GetProfileSettings %*
    if "%MYCELIO_SKIP_INIT%"=="1" goto:$SkipProfileSetup

    REM
    REM This logo was generated with figlet after testing with selection of fonts.
    REM
    REM    - apt install figlet
    REM    - git clone https://github.com/xero/figlet-fonts
    REM    - find figlet-fonts/ -printf "%f\n" | xargs -n 1 -I % figlet -d ./figlet-fonts/ -f % myceli0
    REM
    REM These fonts all display the logo quite well, see https://www.programmingfonts.org
    REM
    REM    - fire code (good but 'I' doesn't align)
    REM    - gintronic (very nice)
    REM    - hasklig (pretty good)
    REM    - jetbrains mono (better than most)
    REM    - julia-mono (amazing)
    REM    - mensch
    REM    - luculent
    REM    - victor mono (quite good)
    REM    - source code pro (bars have spaces)
    REM

    :: Change to unicode
    if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 65001 >NUL 2>&1
    %MYCELIO_ECHO% ▓├═════════════════════════════════
    %MYCELIO_ECHO% ▓│  ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓
    %MYCELIO_ECHO% ▓│  ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃
    %MYCELIO_ECHO% ▓│  ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛
    %MYCELIO_ECHO% ▓├═════════════════════════════════

    :: Switch back to standard ANSI
    if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 1252 >NUL 2>&1

    if not exist "%MYCELIO_ENV_PATH%" goto:$SkipProfileSetup
    %MYCELIO_ECHO% call "%MYCELIO_ENV_PATH%"
    call "%MYCELIO_ENV_PATH%"

    :$SkipProfileSetup
    %MYCELIO_ECHO% [mycelio] Run `help` to get list of commands.

    :: Check to see if 'doskey' is valid first as some versions
    :: of Windows (e.g. nanoserver) do not have 'doskey' support.
    if "%USERNAME%"=="ContainerAdministrator" goto:$SkipDosKeySetup

    :: Some versions of Windows do not support using 'doskey' command
    :: so test it out before running all the commands.
    doskey /? >NUL 2>&1
    if errorlevel 1 goto:$SkipDosKeySetup
        doskey cd.=cd /d "%MYCELIO_ROOT%"
        doskey cd~ =cd /d "%HOME%"
        doskey cp=copy $*
        doskey mv=move $*
        doskey h=doskey /HISTORY
        doskey edit=%HOME%\.local\bin\micro.exe $*
        doskey ls=dir
        doskey refresh=%MYCELIO_ROOT%\source\windows\bin\profile.bat --refresh
        doskey where=@for %%E in (%PATHEXT%) do @for %%I in ($*%%E) do @if NOT "%%~$PATH:I"=="" echo %%~$PATH:I
    :$SkipDosKeySetup

    :: If we have already injected Clink then skip it
    if "%CLINK_INJECTED%"=="1" goto:$SkipClink
        :: This must be the last operation we do.
        call clink --version >NUL 2>&1
        if errorlevel 1 (
            %MYCELIO_ECHO% Initialized `dotfiles` environment without clink.
            call :ClearErrorLevel
        ) else (
            set CLINK_INJECTED=1
            call clink inject --session "dot_mycelio" --profile "%MYCELIO_ROOT%\source\windows\clink" --quiet --nolog
        )
    :$SkipClink
goto:$MainCleanup

::
:: Any final cleanup or operations before exit should go here.
::

:$MainCleanup
set MYCELIO_SKIP_INIT=
