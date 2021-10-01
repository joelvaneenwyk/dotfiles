@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"
call "%~dp0run.bat" "%USERPROFILE%\.local\msys64\usr\bin\bash.exe" %*
