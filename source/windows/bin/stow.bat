@echo off

setlocal EnableDelayedExpansion

call "%~dp0env.bat"

call "%~dp0run.bat" "%PERL%" -I "%MYCELIO_ROOT%\source\stow\lib" ^
    "%MYCELIO_ROOT%\source\stow\bin\stow" ^
    --dir="%MYCELIO_ROOT%\packages" --target="%USERPROFILE%" --verbose %*
