@echo off

set STOW=%~dp0stow\bin

set TEXLIVE_INSTALL=%~dp0.tmp\texlive-install\install-tl-windows.bat
set TEXLIVE_BIN=%~dp0.tmp\texlive\bin\win32

set TEXDIR=%~dp0.tmp\texlive
set TEXMFCONFIG=%~dp0.tmp\texlive\texmf-config
set TEXMFHOME=%~dp0.tmp\texlive\texmf-local
set TEXMFLOCAL=%~dp0.tmp\texlive\texmf-local
set TEXMFSYSCONFIG=%~dp0.tmp\texlive\texmf-config
set TEXMFSYSVAR=%~dp0.tmp\texlive\texmf-var
set TEXMFVAR=%~dp0.tmp\texlive\texmf-var

set TEXLIVE_INSTALL_PREFIX=%~dp0.tmp\texlive
set TEXLIVE_INSTALL_TEXDIR=%~dp0.tmp\texlive
set TEXLIVE_INSTALL_TEXMFCONFIG=%~dp0.tmp\texlive\texmf-config
set TEXLIVE_INSTALL_TEXMFHOME=%~dp0.tmp\texlive\texmf-local
set TEXLIVE_INSTALL_TEXMFLOCAL=%~dp0.tmp\texlive\texmf-local
set TEXLIVE_INSTALL_TEXMFSYSCONFIG=%~dp0.tmp\texlive\texmf-config
set TEXLIVE_INSTALL_TEXMFSYSVAR=%~dp0.tmp\texlive\texmf-var
set TEXLIVE_INSTALL_TEXMFVAR=%~dp0.tmp\texlive\texmf-var

if not "%DOT_INITIALIZED%"=="1" (
    set "PATH=%STOW%;%TEXLIVE_BIN%;%PATH%"
    echo Initializing environment...
)

setlocal EnableDelayedExpansion
    if not exist "%TEXLIVE_BIN%\texi2dvi.exe" (
        rmdir /s /q "%TEXDIR%"
    )

    powershell -File "%~dp0init.ps1"

    set _texInstallCommand="%TEXLIVE_INSTALL%" -no-gui -portable -profile "%~dp0windows\texlive.profile"
    if not exist "%TEXLIVE_BIN%\texi2dvi.exe" (
        echo %_texInstallCommand%
        call %_texInstallCommand%
    )

    call scoop install msys2

    call :MakeHomeLink "%~dp0bash\.bash_aliases"
    call :MakeHomeLink "%~dp0bash\.bashrc"
    call :MakeHomeLink "%~dp0bash\.gitconfig"
    call :MakeHomeLink "%~dp0bash\.gitignore_global"
    call :MakeHomeLink "%~dp0bash\.profile"
    call :MakeHomeLink "%~dp0bash\.ctags"

    call :MakeLink "Documents\WindowsPowerShell" "Microsoft.PowerShell_profile.ps1"
    call :MakeLink "Documents\PowerShell" "Profile.ps1"
    echo Created symbolic links to PowerShell profile: '%~dp0pwsh\Profile.ps1'

    if not exist "%STOW%" (
        msys2 -where "%~dp0" -shell bash -no-start -c ./windows/build-stow.sh
    )
endlocal & (
    set DOT_INITIALIZED=1
)

echo Environment initialized and ready for use.

exit /b %ERRORLEVEL%

:MakeHomeLink
    set _target=%USERPROFILE%\%~nx1
    if exist "%_target%" del "%_target%" > nul 2>&1
    mklink "%_target%" "%~1" > nul 2>&1
    echo Created symbolic links to setting: '%_target%' to '%~1'

    set _msys=%USERPROFILE%\scoop\persist\msys2\home\%USERNAME%\%~nx1
    if exist "%_msys%" del "%_msys%" > nul 2>&1
    mklink "%_msys%" "%~1" > nul 2>&1
    echo Created symbolic links to setting: '%_msys%' to '%~1'
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
