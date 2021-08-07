@echo off

setlocal EnableDelayedExpansion

set _stow=msys2 -where "%~dp0..\" -shell bash -c "stow --verbose %*"
echo [##cmd] %_stow%
call %_stow%
