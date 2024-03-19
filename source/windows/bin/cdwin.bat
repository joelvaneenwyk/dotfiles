@echo off

call "%~dp0env.bat"

docker run -it --rm --name mycelio_test -v %MYCELIO_ROOT%:C:/Users/ContainerAdministrator/dotfiles "mcr.microsoft.com/windows/servercore:ltsc2022" cmd /c "cd c:\Users\ContainerAdministrator\dotfiles && cmd /k %*"
