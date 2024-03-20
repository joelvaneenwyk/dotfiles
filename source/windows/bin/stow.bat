@echo off

setlocal EnableDelayedExpansion EnableExtensions

set _env=%CD%
cd /d "%MYCELIO_ROOT%\packages"
call "%~dp0env.bat"
call "%~dp0run.bat" "%PERL%" -I "%MYCELIO_ROOT%\source\stow\lib" ^
    "%MYCELIO_ROOT%\source\stow\bin\stow" ^
    --dir="%MYCELIO_ROOT%\packages" --target="%USERPROFILE%" --verbose %*
cd /d "%_env%"
