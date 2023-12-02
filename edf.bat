::
:: Execute Dotfile Command ('edf')
::
@echo off
setlocal EnableDelayedExpansion

set "dotfile_root=%~dp0"
set "dotfile_root=%dotfile_root:~0,-1%"

if "%~1"=="clean" (
    call :Clean
    exit /b
)

call "!dotfile_root!\setup.bat" %*
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
    setlocal EnableDelayedExpansion
    set path_to_remove=%~dp0%~1
    if not exist "%path_to_remove%" (
        echo Path already removed: '%~1'
        goto:$RemoveEnd
    )
    rmdir /q /s "%path_to_remove%"
    echo Removed directory: '%path_to_remove%'
    :$RemoveEnd
exit /b
