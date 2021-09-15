@echo off

call "%~dp0..\..\source\windows\env.bat"
"%MYCELIO_ROOT%\source\windows\cdbash.bat" run alpine "apk update && apk add bash && ./setup.sh"
