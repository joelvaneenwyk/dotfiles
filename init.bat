@echo off

chcp 65001 >NUL 2>&1

setlocal EnableExtensions EnableDelayedExpansion

    set STOW=%~dp0stow\bin\stow
    set NAME=mycelio
    set "COMMENT=echo #"
    set "SCRIPT=%~nx0"                              &:# Script name
    set "SNAME=%~n0"                                &:# Script name, without its extension
    set "SPATH=%~dp0" & set "SPATH=!SPATH:~0,-1!"   &:# Script path, without the trailing \
    set "SPROFILE=%~dp0windows\profile.bat"         &:# Full path to profile script
    set ^"ARG0=%0^"                                 &:# Script invokation name
    set ^"ARGS=%*^"                                 &:# Argument line
    set _path=%PATH%
    set _profile_initialized=%DOT_PROFILE_INITIALIZED%
    set "USER[HKLM]=all users"
    set "USER[HKCU]=%USERNAME%"
    set "HIVE="

    if "%~1"=="cls" goto:$SetProfile
    if "%DOT_PROFILE_INITIALIZED%"=="1" goto:$StartInitialize

    :$SetProfile
    call "%~dp0windows\profile.bat"
    set _profile_initialized=1
    set "_path=C:\Program Files (x86)\GnuPG\bin;%~dp0windows;%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\apps\perl\current\perl\bin;%PATH%"

    set _initialize=0

    :$StartInitialize
    if "%~1"=="clean" (
        set _initialize=1
        if exist "%~dp0.tmp" rmdir /s /q "%~dp0.tmp"
        if exist "%~dp0stow\bin\stow" del "%~dp0stow\bin\stow"
        if exist "%~dp0stow\bin\chkstow" del "%~dp0stow\bin\chkstow"
        if exist "%USERPROFILE%\%~1\Documents\WindowsPowerShell" rmdir /q /s "%USERPROFILE%\%~1\Documents\WindowsPowerShell"
        echo Cleared out temporary files and reinitializing environment.
    )

    call :CheckSystemFile "Robocopy.exe"
    call :CheckSystemFile "msiexec.exe"
    call :CheckSystemFile "msi.dll"

    :$CheckArguments
    ::
    :: e.g. init wsl --user jvaneenwyk --distribution Ubuntu
    ::
    :: https://docs.microsoft.com/en-us/windows/wsl/reference
    ::
    if "%~1"=="wsl" (
        wsl %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9 -- bash -c ./init.sh
        exit /b %ERRORLEVEL%
    )

    set _container_platform=%~2
    if "%_container_platform%"=="" (
        set _container_platform=linux
    )

    set _container_name=menv:!_container_platform!
    set _container_instance=menv_!_container_platform!

    ::
    :: Initialize an Ubuntu container for testing.
    ::
    if "%~1"=="docker" (
        docker rm --force "!_container_name!" > nul 2>&1
        docker stop "!_container_instance!" > nul 2>&1

        docker build --rm -t "!_container_name!" -f "%~dp0docker\Dockerfile.!_container_platform!" .
        if errorlevel 1 (
            echo Docker '!_container_name!' container build failed: '%~dp0docker\Dockerfile.!_container_platform!'
        ) else (
            docker run --name "!_container_instance!" -it --rm "!_container_name!"
        )

        exit /b 0
    )

    call :InstallAutoRun

    call msys2 --version > nul 2>&1
    if errorlevel 1 (
        set _initialize=1
    )
    call perl --version > nul 2>&1
    if errorlevel 1 (
        set _initialize=1
    )
    if "%~1"=="-f" (
        set _initialize=1
    )

    set _stow=!_initialize!
    if "%~1"=="stow" (
        set _stow=1
    )

    :$InitializePowerShell
    set _pwsh=
    set _pwshs=
    if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" set _pwshs=!_pwshs! "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    if exist "C:\Program Files\PowerShell\pwsh.exe" set _pwshs=!_pwshs! "C:\Program Files\PowerShell\pwsh.exe"
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" set _pwshs=!_pwshs! "C:\Program Files\PowerShell\7\pwsh.exe"

    for %%p in (!_pwshs!) do (
        echo.
        echo ======-------
        echo Initializing PowerShell: '%%p'
        echo ======-------
        echo.

        set _pwsh=%%p

        %%p -Command "& {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope CurrentUser}"
        echo Updated PowerShell execution policy.

        %%p -File "%~dp0powershell\Initialize-Environment.ps1"
    )

    if "!_initialize!"=="1" (
        call msys2 -where "%~dp0" -shell bash -no-start -c ./init.sh
    )

    if "!_stow!"=="1" (
        set _gitConfig=.gitconfig
        call :WriteGitConfig "%USERPROFILE%"
        call :WriteGitConfig "%USERPROFILE%\scoop\persist\msys2\home"
        call :StowProfile "%~dp0bash\git" ".gitignore_global"

        call :CreateLink "%USERPROFILE%" "%~nx1" "%~1"
        call :CreateLink "%USERPROFILE%\scoop\persist\msys2\home\%USERNAME%" "%~nx1" "%~1"

        call :StowProfile "%~dp0bash\.gnupg" "gpg.conf"
        call :StowProfile "%~dp0bash" ".bash_aliases"
        call :StowProfile "%~dp0bash" ".bashrc"
        call :StowProfile "%~dp0bash" ".profile"
        call :StowProfile "%~dp0bash" ".ctags"

        call :StowPowerShell "Documents\WindowsPowerShell" "Microsoft.PowerShell_profile.ps1"
        call :StowPowerShell "Documents\PowerShell" "Profile.ps1"

        echo Initialized profile settings into local directories for user.
    ) else (
        echo Profile for '%USERNAME%' already initialized.
    )
endlocal & (
    set "DOT_INITIALIZED=1"
    set "DOT_PROFILE_INITIALIZED=%_profile_initialized%"
    set "PATH=%_path%"
    set "POWERSHELL=%_pwsh%"
)

exit /b %ERRORLEVEL%

:CheckSystemFile %1=SystemFilename
    setlocal EnableExtensions EnableDelayedExpansion

    set _deploy="%~dp0.tmp\windows"

    if exist "%_deploy%\%~1" goto:$SystemDeploy

    if not exist "%~dp0.tmp" mkdir "%~dp0.tmp"
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
:: Write .gitconfig
::-----------------------------------
:WriteGitConfig %1=TargetFolder
    setlocal EnableExtensions EnableDelayedExpansion
    set _gitConfig=.gitconfig
    set _gitRoot=%~dp0git
    set "_gitRoot=!_gitRoot:\=/!"
    if exist "%~1" (
        echo.[include] > "%~1\%_gitConfig%"
        echo.    path = "!_gitRoot!/.gitconfig_common">> "%~1\%_gitConfig%"
        echo.    path = "!_gitRoot!/.gitconfig_windows">> "%~1\%_gitConfig%"

        echo Created custom '.gitconfig' with include directives: '%~1'
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
:: Check if the user has system administrator rights. %ERRORLEVEL% 0=Yes; 5=No
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
                %COMMENT% Deleting "!KEY!\AutoRun"
                %EXEC% reg delete "!KEY!" /v "AutoRun" /f
            ) else (
                %COMMENT% Skipped AutoRun installed. Key already exists.
                endlocal & exit /b 0
            )
        )
    )

    :# No keys should exist now so try to install
    if not defined HIVE (
        call :IsAdmin
        if not errorlevel 1 (       :# Admin user. Install for all users.
            set "HIVE=HKLM"
        ) else (        :           # Normal user. Install for current user.
            set "HIVE=HKCU"
        )
    )

    set "KEY=%HIVE%\Software\Microsoft\Command Processor"
    %EXEC% reg add "%KEY%" /v "AutoRun" /t REG_SZ /d "%SPROFILE%" /f
    echo Created registry key "%KEY%" value "AutoRun"
endlocal & exit /b 0

:StowProfile %1=RelativeRoot %2=Filename
    call :CreateLink "%USERPROFILE%\%~1" "%~2" "%~dp0%~1%~2"
    call :CreateLink "%USERPROFILE%\scoop\persist\msys2\home\%USERNAME%\%~1" "%~2" "%~dp0%~1%~2"
exit /b 0

:StowPowerShell
    :: It is very important that we do NOT store PowerShell modules or scripts on OneDrive
    :: as it can cause a lot of problems. We force delete it here which is dangerous but
    :: necessary.
    if exist "%OneDrive%\%~1" (
        rmdir /s /q "%OneDrive%\%~1"
        echo Removed '%OneDrive%\%~1' as modules should not be in OneDrive. See https://stackoverflow.com/a/67531193
    )

    call :CreateLink "%USERPROFILE%\%~1" "%~2" "%~dp0powershell\Profile.ps1"
    call :CreateLink "%USERPROFILE%\%~1" "%~2" "%~dp0powershell\powershell.config.json"
exit /b 0

:CreateLink %1=LinkDirectory %2=LinkFilename %3=TargetPath
    setlocal EnableExtensions EnableDelayedExpansion
    set _linkDir=%~1
    set _linkFilename=%~2
    set _linkTarget=%~3
    if not exist "%_linkDir%" mkdir "%_linkDir%" > nul 2>&1
    if exist "%_linkDir%" (
        if exist "%_linkDir%\%_linkFilename%" del "%_linkDir%\%_linkFilename%"
        mklink "%_linkDir%\%_linkFilename%" "%_linkTarget%" > nul 2>&1
        echo Created symbolic link: '%_linkTarget%' to '%_linkDir%'
    )
exit /b 0
