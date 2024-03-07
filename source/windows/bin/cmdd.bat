@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"

set _action=%~1
shift
if "%_action%"=="" (
    set _action=run
)

set _image=%~1
shift
if "%_image%"=="" (
    set _image=ubuntu:latest
)

:: For loop requires removing trailing backslash from %~dp0 output
set "_current_directory=%CD%"
set "_current_directory=%_current_directory:~0,-1%"
for %%i in ("%_current_directory%") do set "_folder_name=%%~nxi"

echo Docker: '!_action!' '!_image!' in '%cd%'

if "!_action!"=="run" (
    docker run -it --rm  --name "%_folder_name%" -v %cd%:/usr/workspace "%_image%" bash -c "cd /usr/workspace && bash"
) else (
    docker build -t "%_folder_name%" --progress plain -f "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu" "%MYCELIO_ROOT%"
)
