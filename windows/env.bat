@echo off

setlocal EnableDelayedExpansion

set _powershell=

if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set _powershell="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    goto:$BuildEnvironment
)

if exist "C:\Program Files\PowerShell\pwsh.exe" (
    set _powershell="C:\Program Files\PowerShell\pwsh.exe"
    goto:$BuildEnvironment
)

if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
    set _powershell="C:\Program Files\PowerShell\7\pwsh.exe"
    goto:$BuildEnvironment
)
exit /b 1

:$BuildEnvironment
!_powershell! -NoLogo -NoProfile -File "%DOT_PROFILE_ROOT%\powershell\Write-EnvironmentSetup.ps1"
exit /b
