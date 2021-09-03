@echo off

setlocal EnableExtensions EnableDelayedExpansion

if not exist "%MYCELIO_ROOT%" call "%~dp0..\env.bat"
set STOW_ROOT=%MYCELIO_ROOT%\source\stow

del "%STOW_ROOT%\Build" > nul 2>&1
del "%STOW_ROOT%\Build.bat" > nul 2>&1
del "%STOW_ROOT%\config.*" > nul 2>&1
del "%STOW_ROOT%\configure" > nul 2>&1
del "%STOW_ROOT%\configure~" > nul 2>&1
del "%STOW_ROOT%\Makefile" > nul 2>&1
del "%STOW_ROOT%\Makefile.in" > nul 2>&1
del "%STOW_ROOT%\MYMETA.json" > nul 2>&1
del "%STOW_ROOT%\MYMETA.yml" > nul 2>&1
del "%STOW_ROOT%\bin\chkstow" > nul 2>&1
del "%STOW_ROOT%\bin\stow" > nul 2>&1
del "%STOW_ROOT%\lib\Stow\Util.pm" > nul 2>&1
del "%STOW_ROOT%\lib\Stow.pm" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\_build\" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\autom4te.cache\" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\blib\" > nul 2>&1
rmdir /q /s "%STOW_ROOT%\tmp-testing-trees\" > nul 2>&1
