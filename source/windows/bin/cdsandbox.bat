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

echo ##[cmd] !_powershell! -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Initialize-Sandbox.ps1"
!_powershell! -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Initialize-Sandbox.ps1"

call "%~dp0env.bat"
set _sandbox=%MYCELIO_ROOT%\artifacts\sandbox.wsb

if not exist "%_sandbox%" (
    echo Failed to find sandbox template for dotfiles. Please run 'setup.bat' to create it.
    exit /b 11
)
echo ##[cmd] start "" "C:\Windows\System32\WindowsSandbox.exe" "%_sandbox%"
start "" "C:\Windows\System32\WindowsSandbox.exe" "%_sandbox%"
