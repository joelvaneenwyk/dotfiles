@echo off

::
:: Generate environment batch file and then execute it.
::

setlocal EnableDelayedExpansion
    set _powershell=
    set _mycelio_env=%USERPROFILE%\.local\bin\use_mycelio_environment.bat
    set _mycelio_root=%~dp0..\..\..

    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        set _powershell=C:\Program Files\PowerShell\7\pwsh.exe
        goto:$BuildEnvironment
    )

    if exist "C:\Program Files\PowerShell\pwsh.exe" (
        set _powershell=C:\Program Files\PowerShell\pwsh.exe
        goto:$BuildEnvironment
    )

    if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" (
        set _powershell=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
        goto:$BuildEnvironment
    )

    :$BuildEnvironment
    if exist "!_powershell!" (
        if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 437 > nul
        "!_powershell!" -NoLogo -NoProfile -File "%_mycelio_root%\source\powershell\Write-EnvironmentSetup.ps1" -ScriptPath "%_mycelio_env%"
    )
endlocal & (
    set "MYCELEIO_ROOT=%_mycelio_root%"
    set "MYCELIO_POWERSHELL=%_powershell%"
    set "MYCELIO_ENV=%_mycelio_env%"
)

if not exist "%MYCELIO_POWERSHELL%" exit /b 2
if not exist "%MYCELIO_ENV%" exit /b 3

CALL "%MYCELIO_ROOT%\source\stow\tools\stow-environment.bat"
call "%MYCELIO_ENV%"
exit /b
