@echo off

setlocal EnableExtensions EnableDelayedExpansion

set _root=%~dp0..

set _action=%~1
shift
if "%_action%"=="" (
    set _action=run
)

set _image=%~1
shift
if "%_image%"=="" (
    set _image=joelvaneenwyk/msys2
)

:: For loop requires removing trailing backslash from %~dp0 output
set "_current_directory=%CD%"
set "_current_directory=%_current_directory:~0,-1%"
for %%i in ("%_current_directory%") do set "_folder_name=%%~nxi"

echo Docker: '!_action!' '!_image!' in '%cd%'
set _docker=docker run -it --rm  --name "%_folder_name%_msys" -v %cd%:C:\Users\ContainerAdministrator\workspace "%_image%"
echo ##[cmd] %_docker%
%_docker%
