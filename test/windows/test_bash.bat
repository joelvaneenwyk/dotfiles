@echo off

call "%~dp0test_env.bat"
cd /d "%MYCELIO_ROOT%"
"%USERPROFILE%\.local\msys64\usr\bin\bash.exe" -c "%*"
exit /b
