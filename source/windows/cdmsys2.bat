@echo off

setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0env.bat"
set _root=%~dp0../../

:: For loop requires removing trailing backslash from %~dp0 output
set "_current_directory=%CD%"
set "_current_directory=%_current_directory:~0,-1%"
for %%i in ("%_current_directory%") do set "_folder_name=%%~nxi"

set _container_name=dotfiles_msys2
docker rm --force "!_container_name!" > nul 2>&1
docker stop "!_container_instance!" > nul 2>&1

set _cmd=docker build --progress plain --rm -t "!_container_name!" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.msys2" %MYCELIO_ROOT%
echo ##[cmd] !_cmd!
!_cmd!
if errorlevel 1 (
    echo Docker '!_container_name!' container build failed: '%MYCELIO_ROOT%\source\docker\Dockerfile.msys2'
) else (
    docker run --name "!_container_instance!" -it --rm "!_container_name!"
)

::echo Docker: '!_action!' '!_image!' in '%cd%'
::set _docker=docker run -it --rm  --name "%_folder_name%_msys" -v %cd%:C:\Users\ContainerAdministrator\workspace "%_image%"
::echo ##[cmd] %_docker%
::%_docker%
