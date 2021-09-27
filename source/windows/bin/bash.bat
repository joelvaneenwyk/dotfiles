@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"

echo ##[cmd] "%USERPROFILE%\.local\msys64\usr\bin\bash.exe"
call "%USERPROFILE%\.local\msys64\usr\bin\bash.exe"
