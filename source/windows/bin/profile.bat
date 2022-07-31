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
    if "%~1"=="--refresh" goto:$InitializeProfile

    set "CMD=!CMDCMDLINE!"
    set "CMD=!CMD:|=\x7C!"
    set "CMD=!CMD:>=\x3E!"
    set "CMD=!CMD:<=\x3C!"
    set "CMD=!CMD:&=\x36!"

    call :SplitArgs !CMD!

    :: for /f invokes %COMSPEC% without quotes, whereas new shells' ARG0 have quotes. If
    :: ARG0 equals COMSPEC then this is not a new top 'cmd.exe' instance.
    if "!ARG0!"=="%COMSPEC%" (
        set MYCELIO_SKIP_INIT=1
    )

    :: This is not a new top cmd.exe instance
    if /i "!ARG1!"=="/c" (
        set MYCELIO_SKIP_INIT=1
    )

    ::
    :: This is a new top 'cmd.exe' instance so initialize it.
    ::
    if "%MYCELIO_AUTORUN_INITIALIZED%"=="1" set MYCELIO_SKIP_INIT=1
    if "%MYCELIO_PROFILE_INITIALIZED%"=="1" set MYCELIO_SKIP_INIT=1
    if "!MYCELIO_ROOT:~-1!"=="\" set "MYCELIO_ROOT=!MYCELIO_ROOT:~0,-1!"

    :$InitializeProfile
endlocal & (
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    set "MYCELIO_PROFILE_INITIALIZED=1"
    set "MYCELIO_AUTORUN_INITIALIZED=1"
    set "MYCELIO_SKIP_INIT=%MYCELIO_SKIP_INIT%"
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
chcp 65001 >NUL 2>&1
echo ▓├═════════════════════════════════
echo ▓│  ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓
echo ▓│  ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃
echo ▓│  ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛
echo ▓├═════════════════════════════════
echo.

:: Switch back to standard ANSI
chcp 1252 >NUL 2>&1

:: Generate and run the environment batch script
call "%~dp0env.bat"
echo [mycelio] Run `help` to get list of commands.

:: Check to see if 'doskey' is valid first as some versions
:: of Windows (e.g. nanoserver) do not have 'doskey' support.
if "%USERNAME%"=="ContainerAdministrator" goto:$StartClink

:: Some versions of Windows do not support using 'doskey' command
:: so test it out before running all the commands.
doskey /? >NUL 2>&1
if errorlevel 1 goto:$StartClink

    doskey cd.=cd /d "%MYCELIO_ROOT%"
    doskey cd~ =cd /d "%HOME%"
    doskey cp=copy $*
    doskey mv=move $*
    doskey h=doskey /HISTORY
    doskey edit=%HOME%\.local\bin\micro.exe $*
    doskey refresh=%MYCELIO_ROOT%\source\windows\bin\profile.bat --refresh
    doskey where=@for %%E in (%PATHEXT%) do @for %%I in ($*%%E) do @if NOT "%%~$PATH:I"=="" echo %%~$PATH:I

:$StartClink

:: If we have already injected Clink then skip it
if "%CLINK_INJECTED%"=="1" goto:$InitializedProfile

:: This must be the last operation we do.
call clink --version >NUL 2>&1
if errorlevel 1 (
    echo.
    echo Initialized `dotfiles` environment without clink.
) else (
    set CLINK_INJECTED=1
    call clink inject --session "dot_mycelio" --profile "%MYCELIO_ROOT%\source\windows\clink" --quiet --nolog
)

:$InitializedProfile
set MYCELIO_SKIP_INIT=
goto:eof

::-----------------------------------
:: Extract the ARG0 and ARG1 from %CMDCMDLINE% using cmd.exe own parser
::-----------------------------------
:SplitArgs
    set "ARG0=%1"
    set "ARG1=%2"
exit /b
