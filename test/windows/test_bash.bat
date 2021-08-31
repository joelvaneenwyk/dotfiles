@echo off

call "%~dp0..\..\source\windows\env.bat"

cd /d "%MYCELIO_ROOT%"
::"C:\Program Files\Git\bin\bash.exe" -c "%*"
"%USERPROFILE%\scoop\apps\msys2\current\usr\bin\bash.exe" -c "%*"
exit /b
