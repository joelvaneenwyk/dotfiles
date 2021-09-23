::
:: Simple test to make sure secret and public key is setup correctly.
::
@echo off
if not exist "%USERPROFILE%\.tmp" mkdir "%USERPROFILE%\.tmp"
echo test>"%USERPROFILE%\.tmp\gpgtest.txt"
gpg --clearsign <"%USERPROFILE%\.tmp\gpgtest.txt"
