@echo off

call :RemoteWhitespace %*

if "%GITHUB_ACTIONS%"=="" (
    echo ##[cmd] %COMMAND%
) else (
    echo [command]%COMMAND%
)

call %*

exit /b

:RemoteWhitespace
    setlocal enableDelayedExpansion
    set str=%*

    :: Keep removing double spaces until there are none left
    :$WhitespaceLoop
    if defined str (
        set "new=!str:  = !"
        if "!new!" neq "!str!" (
            set "str=!new!"
            goto :$WhitespaceLoop
        )
    )

    if defined str if "!str:~0,1!" equ " " set "str=!str:~1!"
    if defined str if "!str:~-1!" equ " " set "str=!str:~0,-1!"
endlocal & (
    set COMMAND=%str%
)
exit /b
