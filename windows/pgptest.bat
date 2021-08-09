::
:: Simple test to make sure secret and public key is setup correctly.
::
@echo off
if not exist "%~dp0..\.tmp" mkdir "%~dp0..\.tmp"
echo test>"%~dp0..\.tmp\gpgtest.txt"
gpg --clearsign <"%~dp0..\.tmp\gpgtest.txt"
