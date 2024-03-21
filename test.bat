@echo off && goto:$Main

:$Main
setlocal EnableDelayedExpansion
    chcp 65001 1>nul

    set luacheck="%USERPROFILE%\scoop\shims\luacheck.exe"
    if not exist !luacheck! set "luacheck=luacheck"
    !luacheck! .
    if errorlevel 1 goto:$MainError

    set busted="%USERPROFILE%\scoop\shims\busted.exe"
    if not exist !busted! set "busted=busted"
    !busted! .
    if errorlevel 1 goto:$MainError

    :$MainError
    echo [ERROR] Lua tests failed.
endlocal & exit /b 0
