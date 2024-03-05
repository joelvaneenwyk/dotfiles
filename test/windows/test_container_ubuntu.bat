@echo off

call "%~dp0test_env.bat"

docker build --progress plain --rm -t "ubuntu_empty" -f "%MYCELIO_ROOT%\source\docker\Dockerfile.ubuntu" %MYCELIO_ROOT%
"%MYCELIO_ROOT%\source\windows\bin\cdbash.bat" run ubuntu_empty "bash"
