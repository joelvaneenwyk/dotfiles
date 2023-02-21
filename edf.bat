::
:: Execute Dotfile Command ('edf')
::
@echo off
setlocal EnableDelayedExpansion

set "path=%~dp0"
set "path=%path:~0,-1%"

if "%~1"=="clean" (
    call :Clean
    exit /b
)

call "!path!\setup.bat" %*
goto :eof

:Clean
    git clean -xfd
    call :Remove "packages/vim/.vim/bundle/vundle"
    call :Remove "packages/macos/Library/Application Support/Resources"
    call :Remove "packages/fish/.config/base16-shell"
    call :Remove "packages/fish/.config/base16-fzf"
    call :Remove "packages/fish/.config/git-fuzzy"
    call :Remove "test/bats"
    call :Remove "test/test_helper/bats-support"
    call :Remove "test/test_helper/bats-assert"
exit /b

:Remove
    set _path=%~dp0%~1
    if not exist "%_path%" (
        echo Path already removed: '%~1'
        goto:$RemoveEnd
    )
    rmdir /q /s "%_path%"
    echo Removed directory: '%_path%'
    :$RemoveEnd
exit /b
