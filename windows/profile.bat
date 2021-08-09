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

    :: for /f invokes %COMSPEC% without quotes, whereas new shells' ARG0 have quotes.
    if "!ARG0!"=="%COMSPEC%" (
        :# This is not a new top cmd.exe instance
        exit /b 0
    )

    :: This is not a new top cmd.exe instance
    if /i "!ARG1!"=="/c" (
        exit /b 0
    )

    ::
    :: This is a new top 'cmd.exe' instance so initialize it.
    ::

    if "%DOT_AUTORUN_INITIALIZED%"=="1" exit /b 0
    if "%DOT_PROFILE_INITIALIZED%"=="1" exit /b 0

    :$InitializeProfile

    chcp 65001 >NUL 2>&1

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

    echo █├═════════════════════════════════
    echo ▓│
    echo ▓│  ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓
    echo ▓│  ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃
    echo ▓│  ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛
    echo ▓│
    echo ▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

endlocal & (
    set DOT_PROFILE_INITIALIZED=1
    set DOT_AUTORUN_INITIALIZED=1
    set "PATH=C:\Program Files (x86)\GnuPG\bin;%~dp0;%~dp0..;%~dp0..\.tmp;%USERPROFILE%\scoop\apps\perl\current\perl\bin;%USERPROFILE%\scoop\shims;%PATH%"
)

:: Check to see if 'doskey' is valid first as some versions
:: of Windows (e.g. nanoserver) do not have 'doskey' support.
if "%USERNAME%"=="ContainerAdministrator" goto:$StartClink

doskey /? >NUL 2>&1
if errorlevel 1 goto:$StartClink

doskey ls=dir /Q
doskey ll=dir /Q
doskey cp=copy $*
doskey mv=move $*
doskey h=doskey /HISTORY
doskey edit=%~dp0..\.tmp\micro.exe $*
doskey refresh=%~dp0profile.bat --refresh
doskey where=@for %%E in (%PATHEXT%) do @for %%I in ($*%%E) do @if NOT "%%~$PATH:I"=="" echo %%~$PATH:I

:$StartClink
if "%CLINK_INJECTED%"=="1" goto:$InitializedProfile

:: This must be the last operation we do.
call clink --version > nul 2>&1
if errorlevel 1 (
    echo.
    echo Initialized `dotfiles` environment without clink.
) else (
    set CLINK_INJECTED=1
    clink inject --session dot_mycelio --profile "%~dp0clink" --quiet --nolog
)

:$InitializedProfile
exit /b

::-----------------------------------
:: Extract the ARG0 and ARG1 from %CMDCMDLINE% using cmd.exe own parser
::-----------------------------------
:SplitArgs
    set "ARG0=%1"
    set "ARG1=%2"
exit /b
