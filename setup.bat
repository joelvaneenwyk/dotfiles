@echo off

chcp 65001 >NUL 2>&1

setlocal EnableExtensions EnableDelayedExpansion
    set "_mycelio_root=%~dp0"
    set "_starting_directory=%cd%"

    set "MYCELIO_ROOT=%_mycelio_root:~0,-1%"                    &:# Script path, without the trailing \
    set "USER[HKLM]=all users"
    set "USER[HKCU]=%USERNAME%"
    set "HIVE="
    set "HOME=%USERPROFILE%"
    set "COMMENT=echo"
    set "SCRIPT=%~nx0"                                          &:# Script name
    set "SNAME=%~n0"                                            &:# Script name, without its extension
    set ^"ARG0=%0^"                                             &:# Script invokation name
    set ^"ARGS=%*^"                                             &:# Argument line
    set "SPROFILE=%MYCELIO_ROOT%\source\windows\profile.bat"    &:# Full path to profile script
    set "STOW=%MYCELIO_ROOT%\source\stow\bin\stow"

    set "COMMAND=%~1"
    set "_args=%1"
    set _arg_remainder=
    shift

    :: Setup Docker arguments before we parse out argument remainder
    if "!COMMAND!"=="docker" (
        set _container_platform=%~1
        shift
    )

    set _container_name=menv:!_container_platform!
    set _container_instance=menv_!_container_platform!

    set _error=0
    set _clean=0

    :: Keep appending arguments until there are none left
    :$ArgumentParse
    if "%~1"=="-c" set _clean=1
    if "%~1"=="--clean" set _clean=1
    if "%~1"=="clean" set _clean=1
    if "%~1"=="cls" set _clean=1

    set "_args=!_args! %1"
    set "_arg_remainder=!_arg_remainder! %1"
    shift
    if not "%~1"=="" goto :$ArgumentParse

    echo ##[cmd] %SCRIPT% %COMMAND%!_arg_remainder!

    if "!_clean!"=="1" (
        set MYCELIO_PROFILE_INITIALIZED=
        if exist "%MYCELIO_ROOT%\.tmp" rmdir /s /q "%MYCELIO_ROOT%\.tmp" > nul 2>&1
        if exist "%MYCELIO_ROOT%\source\stow\bin\stow" del "%MYCELIO_ROOT%\source\stow\bin\stow" > nul 2>&1
        if exist "%MYCELIO_ROOT%\source\stow\bin\chkstow" del "%MYCELIO_ROOT%\source\stow\bin\chkstow" > nul 2>&1
        if exist "%USERPROFILE%\Documents\PowerShell" rmdir /q /s "%USERPROFILE%\Documents\PowerShell" > nul 2>&1
        if exist "%USERPROFILE%\Documents\WindowsPowerShell" rmdir /q /s "%USERPROFILE%\Documents\WindowsPowerShell" > nul 2>&1
        echo Cleared out temporary files and reinitializing environment.
    )

    :: We intentionally setup autorun as soon as possible especially in case there is an
    :: outdated or invalid version already there since it is called in all subsequent 'call'
    :: commands we issue.
    call :InstallAutoRun
    if not "!ERRORLEVEL!"=="0" (
        set _error=!ERRORLEVEL!
        echo ERROR: AutoRun setup failed.
        goto:$InitializeDone
    )

    call "%MYCELIO_ROOT%\source\windows\profile.bat"
    if not "!ERRORLEVEL!"=="0" (
        set _error=!ERRORLEVEL!
        echo ERROR: Profile setup failed.
        goto:$InitializeDone
    )

    :: These files are missing from Windows Nano Server instances in Docker so either
    :: copy them to local temp folder if running in host or copy them to system folder
    :: if running in a container.
    call :CheckSystemFile "Robocopy.exe"
    call :CheckSystemFile "msiexec.exe"
    call :CheckSystemFile "msi.dll"

    :$CheckArguments
    ::
    :: e.g. init wsl --user jvaneenwyk --distribution Ubuntu
    ::
    :: https://docs.microsoft.com/en-us/windows/wsl/reference
    ::
    if "%COMMAND%"=="wsl" (
        wsl !_arg_remainder! -- bash -c ./setup.sh
        exit /b !ERRORLEVEL!
    )

    ::
    :: Initialize an Ubuntu container for testing.
    ::
    if "%COMMAND%"=="docker" (
        docker rm --force "!_container_name!" > nul 2>&1
        docker stop "!_container_instance!" > nul 2>&1

        set _cmd=docker build --progress plain --rm -t "!_container_name!" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.!_container_platform!" !_arg_remainder! !MYCELIO_ROOT!
        echo ##[cmd] !_cmd!
        !_cmd!
        if errorlevel 1 (
            echo Docker '!_container_name!' container build failed: '%MYCELIO_ROOT%\source\docker\Dockerfile.!_container_platform!'
        ) else (
            docker run --name "!_container_instance!" -it --rm "!_container_name!"
        )

        exit /b 0
    )

    ::
    :: Initialize each installed PowerShell we find
    ::
    set _powershell=
    set _pwshs=
    set _pwshs=!_pwshs! "C:\Program Files\PowerShell\7\pwsh.exe"
    set _pwshs=!_pwshs! "C:\Program Files\PowerShell\pwsh.exe"
    set _pwshs=!_pwshs! "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

    for %%p in (!_pwshs!) do (
        set _powershell=%%p
        if exist !_powershell! goto:$PowerShellSet
    )
    :$PowerShellSet

    echo.
    echo ======-------
    echo Initializing PowerShell: !_powershell!
    echo ======-------
    echo.
    !_powershell! -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Initialize-PowerShell.ps1"

    echo.
    echo ======-------
    echo Installing Windows Dependencies
    echo ======-------
    echo.
    !_powershell! -NoLogo -NoProfile -File "%MYCELIO_ROOT%\source\powershell\Initialize-Environment.ps1" %*
    if not "!ERRORLEVEL!"=="0" (
        set _error=!ERRORLEVEL!
    )

    ::
    :: Re-initialize environment paths now that dependencies are installed
    ::

    call "%MYCELIO_ROOT%\source\windows\env.bat"

    :: The 'stow' tool should now be installed in our local perl so we can
    :: stow the Windows settings. However, due to limitations in 'stow' on Windows
    :: we need to do this in MSYS2 instead.
    ::call "%MYCELIO_ROOT%\source\windows\stow\build.bat"
    ::stow windows

    set MSYS2_PATH_TYPE=minimal
    set MSYS_SHELL=%USERPROFILE%\.local\msys64\msys2_shell.cmd

    :: Initialize 'msys2' ("Minimal System") environment with bash script. We call the shim directly because environment
    :: may not read path properly after it has just been installed.
    echo.
    echo ======-------
    echo Mycelio Environment Setup
    echo ======-------
    echo.
    if not exist "%MSYS_SHELL%" (
        set _error=55
        echo ERROR: MSYS2 [MINGW64] not installed. Initialization failed.
        goto:$InitializeDone
    )

    call "%MSYS_SHELL%" -mingw64 -defterm -no-start -where "%MYCELIO_ROOT%" -shell bash -c "./setup.sh --home /c/Users/%USERNAME% !_args!"
    if not "!ERRORLEVEL!"=="0" (
        set _error=!ERRORLEVEL!
        echo ERROR: MSYS2 [MINGW64] setup process failed.
        goto:$InitializeDone
    )

    :$InitializeDone
    cd /d "%_starting_directory%"
endlocal & (
    set "MYCELIO_ROOT=%MYCELIO_ROOT%"
    set "MYCELIO_PROFILE_INITIALIZED=%MYCELIO_PROFILE_INITIALIZED%"
    set "MYCELIO_ERROR=%_error%"
    set "PATH=%PATH%"
    set "POWERSHELL=%_pwsh%"
)

if "%MYCELIO_ERROR%"=="0" (
    echo Completed execution of `dotfiles` initialization.
) else (
    echo Execution of `dotfiles` initialization failed. Error code: '%MYCELIO_ERROR%'
)

exit /b %MYCELIO_ERROR%

:CheckSystemFile %1=SystemFilename
    setlocal EnableExtensions EnableDelayedExpansion

    set _deploy="%MYCELIO_ROOT%\artifacts\windows"

    if exist "%_deploy%\%~1" goto:$SystemDeploy

    if not exist "%MYCELIO_ROOT%\artifacts" mkdir "%MYCELIO_ROOT%\artifacts"
    if not exist "%_deploy%" mkdir "%_deploy%"

    if exist "C:\Windows\System32\%~1" (
        copy /B /Y /V "C:\Windows\System32\%~1" "%_deploy%\%~1" > nul 2>&1
        echo Copied system file for Docker: '%~1'
    )

    :$SystemDeploy
    :: Windows Nano Server does not include Robocopy so copy our local version
    :: to the currently running server if it exists.
    if not exist "C:\Windows\System32\%~1" (
        copy /B /Y /V "%_deploy%\%~1" "C:\Windows\System32\%~1" > nul 2>&1
        echo Deployed file to 'C:\Windows\System32\' path: '%~1'
    )
endlocal & exit /b

::-----------------------------------
:: Query if autorun installed
::-----------------------------------
:CheckAutoRunInstalled %1=Hive %2=OutputVarName
    setlocal EnableExtensions EnableDelayedExpansion
    set "KEY=%1\Software\Microsoft\Command Processor"
    for /f "tokens=2,3*" %%a in ('reg query "!KEY!" /v AutoRun 2^>NUL ^| findstr AutoRun') do (
        set "TYPE=%%a"
        set "VALUE=%%b"
        if "%~2"=="" echo !USER[%1]!: !VALUE!
        if "!TYPE!"=="REG_EXPAND_SZ" call set "VALUE=!VALUE!"
    )
endlocal & (if not "%~2"=="" (set "%~2=%VALUE%")) & exit /b

::-----------------------------------
:: Check if the user has system administrator rights. !ERRORLEVEL! 0=Yes; 5=No
::-----------------------------------
:IsAdmin
    >NUL 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
exit /b

::-----------------------------------
:: Remove existing auto run and replace it if possible
::-----------------------------------
:InstallAutoRun
    setlocal EnableExtensions EnableDelayedExpansion
    for %%h in (HKLM HKCU) do (
        call :CheckAutoRunInstalled %%h AutoRun
        if defined AutoRun (
            if not "%SPROFILE%"=="!AutoRun!" (
                >&2 echo WARNING: Different AutoRun script already installed for !USER[%%h]!: !AutoRun!

                :# Delete the key otherwise next will display an error
                set "KEY=%%h\Software\Microsoft\Command Processor"
                %EXEC% reg delete "!KEY!" /v "AutoRun" /f
                %COMMENT% Delete existing key: "!KEY!\AutoRun"
            ) else (
                %COMMENT% Profile for dotfiles already registered in AutoRun.
                endlocal & exit /b 0
            )
        )
    )

    :# No keys should exist now so try to install
    if not defined HIVE (
        call :IsAdmin
        if not errorlevel 1 (       :# Admin user. All user install.
            set "HIVE=HKLM"
        ) else (                    :# Normal user. Current user install.
            set "HIVE=HKCU"
        )
    )

    set "KEY=%HIVE%\Software\Microsoft\Command Processor"
    %EXEC% reg add "%KEY%" /v "AutoRun" /t REG_SZ /d "%SPROFILE%" /f
    echo Created registry key "%KEY%" value "AutoRun"
endlocal & exit /b 0
