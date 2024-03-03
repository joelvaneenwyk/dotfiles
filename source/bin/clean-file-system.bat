@echo off
goto:$Main

::
:: Function Definitions
::

:Command
setlocal EnableDelayedExpansion
    goto:$CommandVar
    :CommandVar
        setlocal EnableDelayedExpansion
        set "_command=!%~1!"
        set "_command=!_command:      = !"
        set "_command=!_command:    = !"
        set "_command=!_command:   = !"
        set "_command=!_command:  = !"
        set _error_value=0
        if "%MYCOSHIRO_CRITICAL_ERROR%"=="" goto:$RunCommand
        if "%MYCOSHIRO_CRITICAL_ERROR%"=="0" goto:$RunCommand

        :: Hit critical error so skip the command
        echo [ERROR] Critical error detected. Skipped command: !_command!
        set _error_value=%MYCOSHIRO_CRITICAL_ERROR%
        goto:$CommandDone

        :$RunCommand
        echo ##[cmd] !_command!
        call !_command!
        set _error_value=%ERRORLEVEL%

        :$CommandDone
        endlocal & (
            exit /b %_error_value%
        )
    :$CommandVar

    set "_command=%*"
    call :CommandVar "_command"
endlocal & exit /b

:Sudo
setlocal EnableDelayedExpansion
    if "%VAULT_SUDO_ENABLED%"=="1" goto:$SudoEnabled
    set "VAULT_SUDO_ENABLED=1"
    call :Sudo cache on

    :$SudoEnabled
    call :Command sudo %*
    if "%~1-%~2"=="cache-off" (
        set VAULT_SUDO_ENABLED=0
    )
endlocal & (
    set "VAULT_SUDO_ENABLED=%VAULT_SUDO_ENABLED%"
    exit /b %ERRORLEVEL%
)

:Scoop
setlocal EnableDelayedExpansion
    set "_scoop=C:\Users\%USERNAME%\scoop\shims\scoop.cmd"
    if not exist "!_scoop!" set "_scoop=scoop"
    call :Command "!_scoop!" %*
endlocal & exit /b %ERRORLEVEL%

:ScoopSudo
setlocal EnableDelayedExpansion
    set "_scoop=C:\Users\%USERNAME%\scoop\shims\scoop.cmd"
    if not exist "!_scoop!" set "_scoop=scoop"
    call :Sudo "!_scoop!" %*
endlocal & exit /b %ERRORLEVEL%

:Delete
setlocal EnableExtensions
    if exist "%~1" (
        call :Command rmdir /q /s "%~1"
        echo Removed directory: "%~1"
    ) else (
        echo Directory not found: "%~1"
    )
endlocal & exit /b 0

:Remove
setlocal EnableExtensions
    set "_trash=C:\Users\%USERNAME%\.trash"
    set "_item_to_remove=%~1"
    set "_item_name=%~n1"
    set "_item_trash_directory=%_trash%\%_item_name%"

    if not exist "%_item_to_remove%" (
        echo Skipped removal of non-existent item: "%_item_to_remove%"
        goto:$RemoveEnd
    )
    if not exist "%_trash%" mkdir "%_trash%"

    call :Command move "%_item_to_remove%" "%_item_trash_directory%"
    if not exist "%_item_to_remove%" goto:$RemoveSuccess
    echo [WARNING] Failed to move "%_item_to_remove%" to trash. Trying again with elevated permissions...

    call :Sudo move "%_item_to_remove%" "%_item_trash_directory%"
    if not exist "%_item_to_remove%" goto:$RemoveSuccess
    echo [ERROR] Failed to "%_item_to_remove%" to trash.

    :$RemoveSuccess
    echo Moved "%_item_to_remove%" to trash: "%_item_trash_directory%"

    :$RemoveEnd
endlocal & (
    set "VAULT_SUDO_ENABLED=%VAULT_SUDO_ENABLED%"
    exit /b 0
)

:$Main
setlocal EnableExtensions
    call :Remove "C:\clink"
    call :Remove "C:\.local"
    call :Remove "C:\AMD"
    call :Remove "C:\AITEMP"
    call :Remove "C:\Diskspd"
    call :Remove "C:\PerfLogs"
    call :Remove "C:\Users\source"
    call :Remove "C:\Users\%USERNAME%\.tmp"

    :: First clear local cache
    call :Scoop cleanup --all --cache
    :: Now call scoop with sudo to clear global cache
    call :ScoopSudo cleanup --all --global

    call :Sudo "C:\Windows\System32\powercfg.exe" -h off
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -monitor-timeout-ac 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -monitor-timeout-dc 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -disk-timeout-ac 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -disk-timeout-dc 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -standby-timeout-ac 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -standby-timeout-dc 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -hibernate-timeout-ac 0
    call :Sudo "C:\Windows\System32\powercfg.exe" -x -hibernate-timeout-dc 0

    :: Remove temporary folder
    call :Sudo rmdir /q /s "C:\Users\%USERNAME%\AppData\Local\Temp"
    call :Delete "C:\Users\%USERNAME%\AppData\Local\Temp"

    :$MainEnd
    call :Sudo cache off
endlocal & exit /b 0
