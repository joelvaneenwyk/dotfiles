@echo off

call "%~dp0..\..\source\windows\env.bat"

docker build --progress plain --rm -t "ubuntu_empty" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu.empty" %MYCELIO_ROOT%
"%MYCELIO_ROOT%\source\windows\cdbash.bat" run ubuntu_empty "bash"
