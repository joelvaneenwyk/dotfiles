::
:: Wrapper for Nano Server on Docker since PowerShell is not available by default and installed.
::
@echo off

if [%POWERSHELL%]==[] (
    powershell %*
) else (
    %POWERSHELL% %*
)
