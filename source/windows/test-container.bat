@echo off

"%~dp0cdbash.bat" run alpine "apk update && apk add bash && ./setup.sh"
