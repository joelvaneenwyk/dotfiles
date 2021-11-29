@echo off

setlocal EnableDelayedExpansion

powershell -Command "Set-ExecutionPolicy RemoteSigned -scope CurrentUser"
powershell -File "%~dp0init.ps1"
