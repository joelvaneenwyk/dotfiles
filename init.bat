@echo off

setlocal EnableDelayedExpansion

call :MakeLink "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
call :MakeLink "Documents\PowerShell\Profile.ps1"

powershell -File "%~dp0init.ps1"

exit /b %ERRORLEVEL%

:MakeLink
    set _cloud="%OneDrive%\%~1"
    if exist "%_cloud%" del "%_cloud%"
    mklink "%_cloud%" "%~dp0pwsh\Profile.ps1"

    set _local="%USERPROFILE%\%~1"
    if exist "%_local%" del "%_local%"
    mklink "%_local%" "%~dp0pwsh\Profile.ps1"
exit /b 0
