@echo off && goto:$Main
REM
REM Mycelio - Profile Entrypoint
REM
REM This auto-run script runs for every new cmd executable instance and when
REM running loops in control statements. We do not want it to run initialization
REM steps in loops as it can have unexpected side effects on the parent script
REM variables and can severely impact performance of scripts.
REM

:GetRoot
setlocal EnableDelayedExpansion
    if exist "%MYCELIO_ROOT%\setup.bat" goto:$GetRootDone
    if "%MYCELIO_ROOT%"=="" set "MYCELIO_ROOT=%~dp1"

    :$UpdateRoot
    if "!MYCELIO_ROOT:~-1!"=="\" set "MYCELIO_ROOT=!MYCELIO_ROOT:~0,-1!"
    goto:$GetRootDone

    :$GetRootDone
endlocal & (
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    exit /b %errorlevel%
)

:ClearErrorLevel
exit /b 0

REM
REM Although it is feasible to extract the command for running a new cmd instance
REM from the Command Prompt "lnk" shortcut file using the "WshShell.CreateShortcut"
REM function in JScript and then comparing it to the "CMDCMDLINE" variable but
REM this would be performance heavy to do with each new instance which makes it
REM unacceptable unless we do it only once at install time.
REM
REM The workaround used here is that we check that a fully quoted "COMSPEC" was
REM used while avoiding the "/c" argument. Make sure to use delayed expansion
REM for "CMDCMDLINE" as it may contain unprotected characters.
REM
:GetEnvironment
setlocal EnableDelayedExpansion EnableExtensions
    goto:$GetEnvironmentStart

    REM Local function we later call that extracts ARG0 and ARG1 from
    REM the internal "CMDCMDLINE" variable using the cmd parser.
    :SplitArgs
        set "ARG0=%1"
        set "ARG1=%2"
    exit /b %errorlevel%

    :$GetEnvironmentStart
    set "MYCELIO_SKIP_INIT=0"

    REM Change "REM" to "echo" to get output
    set "ECHO=echo"

    set "_clink=clink"
    where !_clink! >NUL 2>&1
    if errorlevel 1 set "_clink=%USERPROFILE%\scoop\shims\"
    if "%~1"=="--refresh" goto:$InitializeProfile

    set "CMD=!CMDCMDLINE!"
    set "CMD=!CMD:|=\x7C!"
    set "CMD=!CMD:>=\x3E!"
    set "CMD=!CMD:<=\x3C!"
    set "CMD=!CMD:&=\x36!"

    call :SplitArgs !CMD!

    REM When using for loops it invokes COMSPEC without quotes whereas new
    REM shells with ARG0 have quotes. If ARG0 equals COMSPEC then this is not
    REM a new top level instance.
    if "!ARG0!"=="%COMSPEC%" goto:$SkipProfileInitialization

    REM This is not a new top cmd.exe instance
    if /i "!ARG1!"=="/c" goto:$SkipProfileInitialization

    REM This is a new top cmd instance so initialize it.
    if "%MYCELIO_AUTORUN_INITIALIZED%"=="1" goto:$SkipProfileInitialization
    if "%MYCELIO_PROFILE_INITIALIZED%"=="1" goto:$SkipProfileInitialization
    goto:$InitializeProfile

    :$SkipProfileInitialization
    set "MYCELIO_SKIP_INIT=1"
    set "ECHO=REM"

    :$InitializeProfile
    call :GetRoot "%~dp0..\..\..\" "%~dpnx0"

    REM Generate and run the environment batch script
    if not exist "!MYCELIO_ENV_PATH!" (
        set "MYCELIO_ENV_PATH=%~dp0env.bat"
    )
    if not exist "!MYCELIO_ENV_PATH!" (
        set "MYCELIO_ENV_PATH=!MYCELIO_ROOT!\source\windows\bin\env.bat"
    )
    if not exist "!_env!" (
        set "MYCELIO_ENV_PATH="
    )
endlocal & (
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    set "MYCELIO_ENV_PATH=%MYCELIO_ENV_PATH%"
    set "MYCELIO_PROFILE_INITIALIZED=1"
    set "MYCELIO_AUTORUN_INITIALIZED=1"
    set "MYCELIO_SKIP_INIT=%MYCELIO_SKIP_INIT%"
    set "MYCELIO_ECHO=%ECHO%"
    set "HOME=%USERPROFILE%"
)
exit /b %errorlevel%

REM
REM This logo was generated with figlet after testing with selection of fonts.
REM
REM    - apt install figlet
REM    - git clone https://github.com/xero/figlet-fonts
REM    - find figlet-fonts/ -printf "%f\n" ^| xargs -n 1 -I % figlet -d ./figlet-fonts/ -f % myceli0
REM
REM These fonts all display the logo quite well, see https://www.programmingfonts.org
REM
REM    - fire code (good but "I" does not align)
REM    - gintronic (very nice)
REM    - hasklig (pretty good)
REM    - jetbrains mono (better than most)
REM    - julia-mono (amazing)
REM    - mensch
REM    - luculent
REM    - victor mono (quite good)
REM    - source code pro (bars have spaces)
REM
:PrintLogo
    setlocal EnableDelayedExpansion
    if "%MYCELIO_ECHO%"=="REM" goto:$PrintLogoDone
    if "%MYCELIO_ECHO%"=="rem" goto:$PrintLogoDone
    if "%MYCELIO_ECHO%"=="" goto:$PrintLogoDone
    goto:$PrintLogoStart

    :PrintStatement
    call %MYCELIO_ECHO% %~1
    exit /b 0

    :$PrintLogoStart
        REM Change to unicode
        if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 65001 >NUL 2>&1
        call :PrintStatement "▓├═════════════════════════════════"
        call :PrintStatement "▓│  ┏┏┓┓ ┳┏━┓┳━┓┳  o┏━┓"
        call :PrintStatement "▓│  ┃┃┃┗┏┛┃  ┣━ ┃  ┃┃/┃"
        call :PrintStatement "▓│  ┛ ┇ ┇ ┗━┛┻━┛┇━┛┇┛━┛"
        call :PrintStatement "▓├═════════════════════════════════"

        REM Switch back to standard ANSI
        if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 1252 >NUL 2>&1

        goto:$PrintLogoDone

    :$PrintLogoDone
exit /b %errorlevel%

:SetupDosKey
setlocal
    REM Some versions of Windows do not support using "doskey" command
    REM so test it out before running all the commands.
    set "_doskey=C:\Windows\System32\doskey.exe"
    if not exist "%_doskey%" goto:$SkipDosKeySetup

    REM Check to see if "doskey" is valid first as some versions
    REM of Windows like "nanoserver" do not have "doskey" support.
    if "%USERNAME%"=="ContainerAdministrator" goto:$SkipDosKeySetup

    REM Make sure calling doskey works at all before we attempt to setup aliases
    call "%_doskey%" /? >NUL 2>&1
    if errorlevel 1 goto:$SkipDosKeySetup
        call "%_doskey%" cd.=cd /d "%MYCELIO_ROOT%"
        call "%_doskey%" cd~ =cd /d "%HOME%"
        call "%_doskey%" cp=copy $*
        call "%_doskey%" mv=move $*
        call "%_doskey%" h=doskey /HISTORY
        call "%_doskey%" ls=dir $*
        call "%_doskey%" cat=type $*
        call "%_doskey%" edit=%HOME%\.local\bin\micro.exe $*
        call "%_doskey%" refresh=%MYCELIO_ROOT%\source\windows\bin\profile.bat --refresh
    :$SkipDosKeySetup
exit /b %errorlevel%

:$Main
    call :GetEnvironment
    call :PrintLogo

    if "%MYCELIO_SKIP_INIT%"=="1" goto:$MainSkipInit
    if not exist "%MYCELIO_ENV_PATH%" goto:$MainSkipInit
    call "%MYCELIO_ENV_PATH%"
    :$MainSkipInit

    call :SetupDosKey
    %MYCELIO_ECHO% [mycelio] Run `help` to get list of commands.

    REM If we have already injected Clink then skip it
    if "%CLINK_INJECTED%"=="1" goto:$SkipClink
        REM This must be the last operation we do.
        call clink --version >NUL 2>&1
        if errorlevel 1 (
            %MYCELIO_ECHO% Initialized `dotfiles` environment without clink.
            call :ClearErrorLevel
        ) else (
            set CLINK_INJECTED=1
            call clink inject --session "dot_mycelio" --profile "%MYCELIO_ROOT%\source\windows\clink" --quiet --nolog
        )
    :$SkipClink

    :$MycelioProfileEnd
    set "MYCELIO_SKIP_INIT="
    set "MYCELIO_ECHO="
goto:eof
