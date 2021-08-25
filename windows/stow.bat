@echo off

setlocal EnableDelayedExpansion

call "%~dp0env.bat"
set PERL5=C:\Users\%USERNAME%\scoop\apps\msys2\current\usr\bin\perl.exe
set _stow="%PERL5%" -I "%MYCELIO_ROOT%\source\stow\lib" "%MYCELIO_ROOT%\source\stow\bin\stow" --verbose %*
echo [##cmd] %_stow%
call %_stow%
