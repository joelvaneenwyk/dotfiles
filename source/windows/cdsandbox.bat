@echo off

setlocal EnableExtensions EnableDelayedExpansion

::
:: Initialize each installed PowerShell we find
::
set _powershell=
set _pwshs=
set _pwshs=!_pwshs! "C:\Program Files\PowerShell\7\pwsh.exe"
set _pwshs=!_pwshs! "C:\Program Files\PowerShell\pwsh.exe"
set _pwshs=!_pwshs! "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

for %%p in (!_pwshs!) do (
    set _powershell=%%p
    if exist !_powershell! goto:$PowerShellSet
)
:$PowerShellSet

!_powershell! -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Initialize-Sandbox.ps1"

call "%~dp0env.bat"
set _root=%~dp0..\..
set _sandbox=%_root%\artifacts\sandbox.wsb

if not exist "%_sandbox%" (
    echo Failed to find sandbox template for dotfiles. Please run 'setup.bat' to create it.
    exit /b 11
)
start "" "C:\Windows\System32\WindowsSandbox.exe" "%_sandbox%"
