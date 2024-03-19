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

    set _name=%_folder_name%__!_image!
    set _name=!_name::=_!
    set _name=!_name:.=_!

    if "!_args!"=="" set _args=bash
    set _shell_cmd=cd /usr/workspace ^&^& !_args
    echo Docker: '!_action!' '!_image!' in '%cd%'
    call "%~dp0run.bat" docker run -it --rm  --name "!_name!" -v %cd%:/usr/workspace "%_image%" sh -c "!_shell_cmd!"
exit /b
