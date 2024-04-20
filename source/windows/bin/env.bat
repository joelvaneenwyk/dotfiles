::
:: Call PowerShell to generate a batch script that sets up the
:: environment variables for the current user.
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
    if not exist "%USERPROFILE%\.local" mkdir "%USERPROFILE%\.local"
    if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"

    set "_powershell=C:\Program Files\PowerShell\7\pwsh.exe"
    if exist "!_powershell!" goto:$BuildEnvironment

    set "_powershell=C:\Program Files\PowerShell\pwsh.exe"
    if exist "!_powershell!" goto:$BuildEnvironment

    set "_powershell=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    if exist "!_powershell!" goto:$BuildEnvironment

    set "_powershell="
    goto:$GenerateDone

    :$BuildEnvironment
        if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 437 > nul
        call "!_powershell!" ^
            -NoLogo -NoProfile ^
            -File "%MYCELIO_ROOT%\source\powershell\Write-EnvironmentSetup.ps1" ^
            -ScriptPath "%_mycelio_env%"
        goto:$GenerateDone

    :$GenerateDone
endlocal & (
    set "MYCELIO_LAST_ERROR=%errorlevel%"
    set "MYCELIO_POWERSHELL=%_powershell%"
    set "MYCELIO_ENV=%_mycelio_env%"
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
)
exit /b %MYCELIO_LAST_ERROR%

:SetError
exit /b %~1

:$Main
    call :Generate %*

    if exist "%MYCELIO_ENV%" (
        call "%MYCELIO_ENV%"
    ) else (
        echo [ERROR] Failed to setup environment.
        exit /b 90
    )

    if not exist "%MYCELIO_POWERSHELL%" (
        echo [ERROR] PowerShell not found.
        exit /b 91
    )
exit /b 0
