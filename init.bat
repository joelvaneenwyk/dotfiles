@echo off

setlocal EnableDelayedExpansion

call :MakeHomeLink "%~dp0bash\.bash_aliases"
call :MakeHomeLink "%~dp0bash\.bashrc"
call :MakeHomeLink "%~dp0bash\.gitconfig"
call :MakeHomeLink "%~dp0bash\.gitignore_global"
call :MakeHomeLink "%~dp0bash\.profile"
call :MakeHomeLink "%~dp0bash\.ctags"

call :MakeLink "Documents\WindowsPowerShell" "Microsoft.PowerShell_profile.ps1"
call :MakeLink "Documents\PowerShel" "Profile.ps1"
echo Created symbolic links to PowerShell profile: '%~dp0pwsh\Profile.ps1'

powershell -File "%~dp0init.ps1"

exit /b %ERRORLEVEL%

:MakeHomeLink
    if exist "%USERPROFILE%\%~nx1" del "%USERPROFILE%\%~nx1" > nul 2>&1
    mklink "%USERPROFILE%\%~nx1" "%~1" > nul 2>&1
    echo Created symbolic links to setting: '%USERPROFILE%\%~nx1' to '%~1'
exit /b 0

:MakeLink
    set _cloud=%OneDrive%\%~1
    if exist "%_cloud%" (
        if exist "%_cloud%\%~2" del "%_cloud%\%~2" > nul 2>&1
        mklink "%_cloud%\%~2" "%~dp0pwsh\Profile.ps1" > nul 2>&1
    )

    set _local=%USERPROFILE%\%~1
    if exist "%_local%" (
        if exist "%_local%\%~2" del "%_local%\%~2"
        mklink "%_local%\%~2" "%~dp0pwsh\Profile.ps1" > nul 2>&1
    )
exit /b 0
