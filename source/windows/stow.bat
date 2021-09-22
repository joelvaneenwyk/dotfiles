@echo off

setlocal EnableDelayedExpansion

call "%~dp0env.bat"
set PERL=%USERPROFILE%\.local\perl\perl\bin\perl.exe
set _stow="%PERL%" -I "%MYCELIO_ROOT%\source\stow\lib" "%MYCELIO_ROOT%\source\stow\bin\stow" --dir="%MYCELIO_ROOT%\packages" --target="%USERPROFILE%" --verbose %*
echo ##[cmd] %_stow%
call %_stow%
