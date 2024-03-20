@echo off

call "%~dp0test_env.bat"
"%MYCELIO_ROOT%\source\windows\bin\cdbash.bat" run alpine "apk update && apk add bash && ./setup.sh"
