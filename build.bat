@echo off
goto:$Main

:Build
setlocal EnableDelayedExpansion
    set "dotfiles_root=%~dp0"
    if "%dotfiles_root:~-1%"=="\" set "dotfiles_root=%dotfiles_root:~0,-1%"

    set "docker_filename=%~1"
    if "%docker_filename%"=="" set "docker_filename=Dockerfile.ubuntu"

    set "docker_exe=C:\Program Files\Docker\Docker\resources\bin\docker.exe"

    set "command_args="!docker_exe!" build -f "!dotfiles_root!\source\docker\!docker_filename!" --pull --force-rm "!dotfiles_root!" "
    echo ##[cmd] !command_args!
    call !command_args!
endlocal & exit /b %ERRORLEVEL%

:$Main
setlocal EnableDelayedExpansion
    call :Build "Dockerfile.ubuntu"
    if errorlevel 1 goto:$MainError

    call :Build "Dockerfile.alpine"
    if errorlevel 1 goto:$MainError

    echo [INFO] Successfully built Docker images for 'dotfiles' project.
    goto:$MainDone

    :$MainError
    echo [ERROR] Failed to build Docker image.
    goto:$MainDone

    :$MainDone
endlocal & exit /b %ERRORLEVEL%
