@echo off
::
:: This is used as an auto-run script and invoked for every new instance of 'cmd.exe' starts. This script
:: is also invoked when running e.g. 'for /f %%l in ('some command') do ...'
::
:: In those cases we do not want to run the initialization as it can haveunexpected side effects on the parent
:: script variables. This severly affects the performance of scripts that heavily use for loops.
::
:: The command for running a new cmd instance is available in the "Command Prompt.lnk" shortcut and would be
:: feasible to extract it from there using JScript WshShell.Createshortcut() and then compare it to %CMDCMDLINE% variable
:: but the performance penalty each time a cmd.exe starts would not be acceptable unless we do it only once
:: at install time.
::
:: Workaround used here is that we check that a full quoted COMSPEC was used and _not_ using '/c' argument
::
:: IMPORTANT: Do not use %CMDCMDLINE% as is may contain unprotected | & > < characters. Use !CMDCMDLINE! instead.
::

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

    call :FindTool clink_executable clink
    if not exist "!clink_executable!" set "clink_executable=C:\Program Files (x86)\clink\clink_x64.exe"
    if not exist "!clink_executable!" set "clink_executable=C:\Program Files\clink\clink_x64.exe"
    if not exist "!clink_executable!" set "clink_executable=clink"
    call :ClearErrorLevel
    call "!clink_executable!" --version >NUL 2>&1
    if errorlevel 1 set "clink_executable="

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
        set "MYCELIO_ENV_PATH=!MYCELIO_ROOT!\source\windows\bin\profile.bat"
    )
endlocal & (
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    set "MYCELIO_ENV_PATH=%MYCELIO_ENV_PATH%"
    set "MYCELIO_CLINK=%clink_executable%"
    set "MYCELIO_PROFILE_INITIALIZED=1"
    set "MYCELIO_AUTORUN_INITIALIZED=1"
    set "MYCELIO_SKIP_INIT=%MYCELIO_SKIP_INIT%"
    set "MYCELIO_ECHO=%ECHO%"
)
if "%MYCELIO_SKIP_INIT%"=="1" goto:$InitializedProfile

::
:: This logo was generated with figlet after testing with selection of fonts.
::
::    - apt install figlet
::    - git clone https://github.com/xero/figlet-fonts
::    - find figlet-fonts/ -printf "%f\n" | xargs -n 1 -I % figlet -d ./figlet-fonts/ -f % myceli0
::
:: These fonts all display the logo quite well, see https://www.programmingfonts.org
::
::    - fire code (good but 'I' doesn't align)
::    - gintronic (very nice)
::    - hasklig (pretty good)
::    - jetbrains mono (better than most)
::    - julia-mono (amazing)
::    - mensch
::    - luculent
::    - victor mono (quite good)
::    - source code pro (bars have spaces)
::

:: Change to unicode
if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 65001 >NUL 2>&1
%MYCELIO_ECHO% ▓├═════════════════════════════════
%MYCELIO_ECHO% ▓│  ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓
%MYCELIO_ECHO% ▓│  ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃
%MYCELIO_ECHO% ▓│  ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛
%MYCELIO_ECHO% ▓├═════════════════════════════════

:: Switch back to standard ANSI
if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 1252 >NUL 2>&1

if not exist "%MYCELIO_ENV_PATH%" goto:$InitializedProfile
call "%MYCELIO_ENV_PATH%"

:$InitializedProfile
%MYCELIO_ECHO% [mycelio] Run `help` to get list of commands.

:: Check to see if 'doskey' is valid first as some versions
:: of Windows (e.g. nanoserver) do not have 'doskey' support.
if "%USERNAME%"=="ContainerAdministrator" goto:$StartClink

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

goto:$MycelioProfileEnd

::-----------------------------------
:: Extract the ARG0 and ARG1 from %CMDCMDLINE% using cmd.exe own parser
::-----------------------------------
:SplitArgs
    set "ARG0=%1"
    set "ARG1=%2"
exit /b

:FindTool
    setlocal EnableExtensions EnableDelayedExpansion
        set _output_variable=%~1
        set _file=%~2

        :: If the variable already contains a valid path, then exit early
        set _output=!%_output_variable%!
        if exist "!_output!" goto:$FindToolDone

        set _where=%SystemRoot%\System32\WHERE.exe
        if not exist "%_where%" goto:$FindToolDone
        "!_where!" /Q %_file%
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

:ClearErrorLevel
exit /b 0

:$MycelioProfileEnd
set MYCELIO_SKIP_INIT=
