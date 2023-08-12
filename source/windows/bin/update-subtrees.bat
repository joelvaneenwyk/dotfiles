@echo off
setlocal EnableDelayedExpansion EnableExtensions

call :ClearErrorLevel

call :GitSubtreeUpdate "source\windows\clink-completions" "https://github.com/vladimir-kotikov/clink-completions" "master"
exit /b

call :GitSubtreeUpdate
goto:eof

:GitSubtreeUpdate
    setlocal EnableExtensions EnableDelayedExpansion

    set "prefix=%~1"
    set "prefix=%prefix:\=/%"
    set "local_path=%~dp0%~1"
    set "remote=%~2"
    set "branch=%~3"
    if "%~3"=="" set "branch=main"
    set "git_subtree_args=--prefix="%prefix%" "%remote%" %branch% --squash --debug"

    cd /D "%~dp0"

    echo Path: "!local_path!"
    if exist "!local_path!" goto :GitSubtreeExists
    set "git_cmd=git subtree add !git_subtree_args!"
    echo ##[cmd] !git_cmd!
    !git_cmd!
    if not exist "!local_path!" exit /b 11

    :GitSubtreeExists
    set "git_cmd=git subtree pull !git_subtree_args!"
    echo ##[cmd] !git_cmd!
    !git_cmd!
exit /b

::
:: Functions
::

:: Simple function that just returns zero to clear the error level
:ClearErrorLevel
exit /b 0
