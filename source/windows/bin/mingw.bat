@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"
call "%~dp0run.bat" "%USERPROFILE%\.local\msys64\msys2_shell.cmd" ^
    -mingw64 -defterm -no-start -where "%MYCELIO_ROOT%" -shell bash
