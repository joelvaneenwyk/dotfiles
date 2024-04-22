::
:: Install the Windows Driver Kit (WDK) for Visual Studio 2022
::

@echo off
goto:$Main

:$Main
    :: sudo winget install --source winget --exact --id Microsoft.VisualStudio.2022.Community --override "--passive --config %~dp0wdk.vsconfig"
    :: sudo winget install --source winget --exact --id Microsoft.WindowsSDK.10.0.22621 --log "%~dp0sdk-install.log"
    :: sudo winget install --source winget --exact --id Microsoft.WindowsWDK.10.0.22621 --log "%~dp0wdk-install.log"
    for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -nologo -latest -products * -property enginePath`) do (
      "%%i\VSIXInstaller.exe" "%ProgramFiles(x86)%\Windows Kits\10\Vsix\VS2022\10.0.22621.0\WDK.vsix"
    )
exit /b 0
