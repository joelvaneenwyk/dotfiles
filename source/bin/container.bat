@echo off
setlocal EnableDelayedExpansion

:: {
::     "builder": {
::         "gc": {
::             "defaultKeepStorage": "20GB",
::             "enabled": true
::         }
::     },
::     "experimental": false,
::     "debug": true,
::     "data-root": "D:\\Docker\\Data\\Linux",
::     "features": {
::         "buildkit": false
::     }
:: }

@echo off
if "%~1"=="delete" (
    call :DockerFlush
    goto:eof
)

echo Pass 'delete' as first argument if you want to delete.
exit /b 1

:DockerFlush
    wsl --shutdown

    call :Delete "C:\ProgramData\Docker"
    call :Delete "C:\ProgramData\DockerDesktop"
    call :Delete "%USERPROFILE%\AppData\Roaming\Docker"
    call :Delete "%USERPROFILE%\AppData\Roaming\DockerDesktop"
    call :Delete "%USERPROFILE%\AppData\Local\Docker"

    :: mklink /j "C:\ProgramData\Docker" "D:\Docker\ProgramData\Docker"
    :: mklink /j "C:\ProgramData\DockerDesktop" "D:\Docker\ProgramData\DockerDesktop"
exit /b

:Delete
    if exist "%~1" rmdir /s /q "%~1"
    echo Removed directory: "%~1"
exit /b
