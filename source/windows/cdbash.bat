@echo off

setlocal EnableExtensions EnableDelayedExpansion

set _root=%~dp0..
set _action=run
set _image=bash:3.1
set _args=

if "%~1"=="" goto:$StartDocker
set _action=%~1
shift

if "%~1"=="" goto:$StartDocker
set _image=%~1
shift

:$ArgumentParse
if "%~1"=="" goto :$StartDocker
set "_args=!_args! %~1"
shift
goto :$ArgumentParse

:$StartDocker

    :: For loop requires removing trailing backslash from %~dp0 output
    set "_current_directory=%CD%"
    set "_current_directory=%_current_directory:~0,-1%"
    for %%i in ("%_current_directory%") do set "_folder_name=%%~nxi"

    echo Docker: '!_action!' '!_image!' in '%cd%'
    echo ##[cmd] docker run -it --rm  --name "%_folder_name%__!_image!" -v %cd%:/usr/workspace "%_image%" sh -c "cd /usr/workspace && !_args!"
    docker run -it --rm  --name "%_folder_name%__!_image!" -v %cd%:/usr/workspace "%_image%" sh -c "cd /usr/workspace && !_args!"

exit /b
