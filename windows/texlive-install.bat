@echo off

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

set _texInstallCommand="%TEXLIVE_INSTALL%" -no-gui -portable -profile "%~dp0windows\texlive.profile"
if not exist "%TEXLIVE_BIN%\texi2dvi.exe" (
    echo %_texInstallCommand%
    call %_texInstallCommand%
)
