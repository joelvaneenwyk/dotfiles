::
:: Simple test to make sure secret and public key is setup correctly.
::
@echo off

setlocal EnableDelayedExpansion

if not exist "%USERPROFILE%\.tmp" mkdir "%USERPROFILE%\.tmp"
echo test>"%USERPROFILE%\.tmp\gpgtest.txt"

set _gpg=gpg
"!_gpg!" --version >NUL 2>&1
if "%ERRORLEVEL%"=="0" goto:$RecoverSecretKey

set _gpg=C:\Program Files (x86)\GnuPG\bin\gpg.exe
"!_gpg!" --version >NUL 2>&1
if not "%ERRORLEVEL%"=="0" (
    echo ERROR: 'gpg' not found. Please run 'setup.bat' to install 'gpg4win' toolset.
    exit /b 99
)

:$RecoverSecretKey
"!_gpg!" --clearsign <"%USERPROFILE%\.tmp\gpgtest.txt"
