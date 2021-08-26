@echo off

set TEXLIVE_INSTALL=%USERPROFILE%\.tmp\texlive-install\install-tl-windows.bat
set TEXLIVE_BIN=%USERPROFILE%\.tmp\texlive\bin\win32

set TEXDIR=%USERPROFILE%\.tmp\texlive
set TEXMFCONFIG=%USERPROFILE%\.tmp\texlive\texmf-config
set TEXMFHOME=%USERPROFILE%\.tmp\texlive\texmf-local
set TEXMFLOCAL=%USERPROFILE%\.tmp\texlive\texmf-local
set TEXMFSYSCONFIG=%USERPROFILE%\.tmp\texlive\texmf-config
set TEXMFSYSVAR=%USERPROFILE%\.tmp\texlive\texmf-var
set TEXMFVAR=%USERPROFILE%\.tmp\texlive\texmf-var

set TEXLIVE_INSTALL_PREFIX=%USERPROFILE%\.tmp\texlive
set TEXLIVE_INSTALL_TEXDIR=%USERPROFILE%\.tmp\texlive
set TEXLIVE_INSTALL_TEXMFCONFIG=%USERPROFILE%\.tmp\texlive\texmf-config
set TEXLIVE_INSTALL_TEXMFHOME=%USERPROFILE%\.tmp\texlive\texmf-local
set TEXLIVE_INSTALL_TEXMFLOCAL=%USERPROFILE%\.tmp\texlive\texmf-local
set TEXLIVE_INSTALL_TEXMFSYSCONFIG=%USERPROFILE%\.tmp\texlive\texmf-config
set TEXLIVE_INSTALL_TEXMFSYSVAR=%USERPROFILE%\.tmp\texlive\texmf-var
set TEXLIVE_INSTALL_TEXMFVAR=%USERPROFILE%\.tmp\texlive\texmf-var

set _texInstallCommand="%TEXLIVE_INSTALL%" -no-gui -portable -profile "%~dp0windows\texlive.profile"
if not exist "%TEXLIVE_BIN%\texi2dvi.exe" (
    echo %_texInstallCommand%
    call %_texInstallCommand%
)
