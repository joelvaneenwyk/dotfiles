@echo off
setlocal EnableDelayedExpansion
set "dotfiles_root=%~dp0"
if "%dotfiles_root:~-1%"=="\" set "dotfiles_root=%dotfiles_root:~0,-1%"
set command_args=docker build -f "!dotfiles_root!\source\docker\Dockerfile.ubuntu" --pull --force-rm %* "!dotfiles_root!"
echo ##[cmd] !command_args!
call !command_args!
