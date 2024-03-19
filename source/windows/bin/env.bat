::
::
::
@echo off
goto:$Main

::
:: Generate environment batch file and then execute it.
::
:Generate
setlocal EnableDelayedExpansion
    goto:$GetRoot
    :GetRoot
        if not exist "%MYCELIO_ROOT%\setup.bat" set "MYCELIO_ROOT=%~dp1"
        if "!MYCELIO_ROOT:~-1!"=="\" set "MYCELIO_ROOT=!MYCELIO_ROOT:~0,-1!"
    exit /b 0
    :$GetRoot

    call :GetRoot "%~dp0..\..\..\"

    set "_mycelio_env=%USERPROFILE%\.local\bin\use_mycelio_environment.bat"
    set _powershell=
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        set "_powershell=C:\Program Files\PowerShell\7\pwsh.exe"
        goto:$BuildEnvironment
    )

    if exist "C:\Program Files\PowerShell\pwsh.exe" (
        set "_powershell=C:\Program Files\PowerShell\pwsh.exe"
        goto:$BuildEnvironment
    )

    if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" (
        set "_powershell=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        goto:$BuildEnvironment
    )

    :$BuildEnvironment
    if not exist "!_powershell!" goto:$SkipPowerShellSetup
        if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 437 > nul
        "!_powershell!" -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Write-EnvironmentSetup.ps1" -ScriptPath "%_mycelio_env%"
    :$SkipPowerShellSetup
endlocal & (
    set "MYCELIO_POWERSHELL=%_powershell%"
    set "MYCELIO_ENV=%_mycelio_env%"
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    exit /b %errorlevel%
)

:SetError
exit /b %~1

:$Main
setlocal EnableExtensions
    call :Generate
    if not exist "%MYCELIO_POWERSHELL%" (
        call :SetError 2
        goto:$MainDone
    )
    :$MainDone
endlocal & (
    set "MYCELIO_POWERSHELL=%_powershell%"
    set "MYCELIO_ENV=%_mycelio_env%"
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    exit /b %errorlevel%
)

if exist "%MYCELIO_ENV%" (
    call "%MYCELIO_ENV%"
) else (
    echo [ERROR] Failed to setup environment.
    exit /b 77
)
