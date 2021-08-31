@echo off

setlocal EnableDelayedExpansion

call "%~dp0env.bat"
set PERL=%USERPROFILE%\scoop\apps\perl\current\perl\bin\perl.exe
set _stow="%PERL%" "%USERPROFILE%\scoop\apps\perl\current\perl\site\bin\stow" --dir="%MYCELIO_ROOT%" --target="%USERPROFILE%" --verbose %*
echo ##[cmd] %_stow%
call %_stow%
