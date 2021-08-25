@echo off

setlocal EnableDelayedExpansion

set PERL5LIB=%~dp0..\source\stow\lib;%PERL5LIB%
set PERL5=C:\Users\%USERNAME%\scoop\apps\msys2\current\usr\bin\perl.exe
set CYGPATH=C:\Users\%USERNAME%\scoop\apps\msys2\current\usr\bin\cygpath.exe

FOR /F "tokens=* USEBACKQ" %%F IN (`command`) DO (
SET var=%%F
)
ECHO %var%
::set _stow=msys2 -where "%~dp0..\" -shell bash -c "stow --verbose %*"
set _stow="%PERL5%" "%~dp0..\source\stow\bin\stow" --verbose %*
echo [##cmd] %_stow%
call %_stow%
