@echo off

set STOW=%~dp0stow\bin\stow

if "%~1"=="clean" (
    set DOT_INITIALIZED=
    if exist "%~dp0.tmp" rmdir /s /q "%~dp0.tmp"
    if exist "%~dp0stow\bin\stow" del "%~dp0stow\bin\stow"
    if exist "%~dp0stow\bin\chkstow" del "%~dp0stow\bin\chkstow"
    echo Cleared out temporary files and reinitializing environment.
)

if not "%DOT_INITIALIZED%"=="1" (
    set "PATH=%~dp0windows;%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\apps\perl\current\perl\bin;%PATH%"
    echo Initializing environment...
)

setlocal EnableDelayedExpansion
    ::
    :: e.g. init wsl --user jvaneenwyk --distribution Ubuntu
    ::
    :: https://docs.microsoft.com/en-us/windows/wsl/reference
    ::
    if "%~1"=="wsl" (
        wsl %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9 -- bash -c ./init.sh
        exit /b %ERRORLEVEL%
    )

    set _container_platform=%~2
    if "%_container_platform%"=="" (
        set _container_platform=linux
    )

    set _container_name=menv:!_container_platform!
    set _container_instance=menv_!_container_platform!

    ::
    :: Initialize an Ubuntu container for testing.
    ::
    if "%~1"=="docker" (
        docker rm --force "!_container_name!" > nul 2>&1
        docker stop "!_container_instance!" > nul 2>&1

        docker build -t "!_container_name!" -f "%~dp0docker\Dockerfile.!_container_platform!" .

        if %ERRORLEVEL% EQU 0 (
            docker run --name "!_container_instance!" -it --rm "!_container_name!"
        ) else (
            echo Docker build failed.
        )

        exit /b 0
    )

    set _pwsh=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
    if not exist !_pwsh! set _pwsh=C:\Program Files\PowerShell\pwsh.exe
    if not exist !_pwsh! set _pwsh=C:\Program Files\PowerShell\7\pwsh.exe

    call !_pwsh! -Command "& {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope CurrentUser}" > nul 2>&1
    call !_pwsh! -File "%~dp0powershell\Initialize-Environment.ps1"

    call msys2 --version > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        call scoop install msys2
    )
    call msys2 -where "%~dp0" -shell bash -no-start -c ./init.sh

    call perl --version > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        call scoop install perl
    )

    call :MakeHomeLink "%~dp0bash\.bash_aliases"
    call :MakeHomeLink "%~dp0bash\.bashrc"
    call :MakeHomeLink "%~dp0bash\.gitconfig"
    call :MakeHomeLink "%~dp0bash\.gitignore_global"
    call :MakeHomeLink "%~dp0bash\.profile"
    call :MakeHomeLink "%~dp0bash\.ctags"

    call :MakeLink "Documents\WindowsPowerShell" "Microsoft.PowerShell_profile.ps1"
    call :MakeLink "Documents\PowerShell" "Profile.ps1"
endlocal & (
    set DOT_INITIALIZED=1
)

echo Environment initialized and ready for use.

exit /b %ERRORLEVEL%

:MakeHomeLink
    call :CreateLink "%USERPROFILE%" "%~nx1" "%~1"
    call :CreateLink "%USERPROFILE%\scoop\persist\msys2\home\%USERNAME%" "%~nx1" "%~1"
exit /b 0

:MakeLink
    call :CreateLink "%OneDrive%\%~1" "%~2" "%~dp0powershell\Profile.ps1"
    call :CreateLink "%USERPROFILE%\%~1" "%~2" "%~dp0powershell\Profile.ps1"
exit /b 0

:CreateLink
    set _linkDir=%~1
    set _linkFilename=%~2
    set _linkTarget=%~3
    if exist "%_linkDir%" (
        if exist "%_linkDir%\%_linkFilename%" del "%_linkDir%\%_linkFilename%"
        mklink "%_linkDir%\%_linkFilename%" "%_linkTarget%" > nul 2>&1
        echo Created symbolic link: '%_linkTarget%' to '%_linkDir%'
    )
exit /b 0
