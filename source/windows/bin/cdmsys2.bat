@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"

:: For loop requires removing trailing backslash from %~dp0 output
set "_current_directory=%CD%"
set "_current_directory=%_current_directory:~0,-1%"
for %%i in ("%_current_directory%") do set "_folder_name=%%~nxi"

set _container_name=dotfiles_msys2
call "%~dp0run.bat" docker rm --force "!_container_name!" > nul 2>&1
call "%~dp0run.bat" docker stop "!_container_instance!" > nul 2>&1

call "%~dp0run.bat" docker build --progress plain --rm -t "!_container_name!" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.msys2" %MYCELIO_ROOT%
if errorlevel 1 (
    echo Docker '!_container_name!' container build failed: '%MYCELIO_ROOT%\source\docker\Dockerfile.msys2'
) else (
    call "%~dp0run.bat" docker run --name "!_container_instance!" -it --rm "!_container_name!"
)
