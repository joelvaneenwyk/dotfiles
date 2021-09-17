@echo off

call "%~dp0..\..\source\windows\env.bat"

cd /d "%MYCELIO_ROOT%"
::"C:\Program Files\Git\bin\bash.exe" -c "%*"
"%USERPROFILE%\.local\msys64\usr\bin\bash.exe" -c "%*"
exit /b
