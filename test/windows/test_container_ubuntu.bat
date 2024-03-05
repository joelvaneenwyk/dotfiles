@echo off
goto:$Main

:SetError
exit /b %~1

:$Main
setlocal EnableExtensions
    if not exist "%~dp0test_env.bat" (
        echo [ERROR] Failed to find script:  "%~dp0test_env.bat"
        call :SetError 1
        goto:$MainDone
    )
    call "%~dp0test_env.bat"

    if not exist "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu" (
        echo [ERROR] Failed to find Dockerfile: "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu"
        call :SetError 2
        goto:$MainDone
    )
    call docker build --rm -t "ubuntu_empty" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu" %MYCELIO_ROOT%

    if not exist "%MYCELIO_ROOT%\source\windows\bin\cdbash.bat" (
        echo [ERROR] Failed to find script: "%MYCELIO_ROOT%\source\windows\bin\cdbash.bat"
        call :SetError 3
        goto:$MainDone
    )
    call "%MYCELIO_ROOT%\source\windows\bin\cdbash.bat" run ubuntu_empty "bash"

    :$MainDone
endlocal & (
    exit /b %errorlevel%
)
