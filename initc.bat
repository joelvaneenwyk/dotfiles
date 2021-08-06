@echo off
::
:: Helper script to initialize an Ubuntu container for testing.
::

setlocal EnableDelayedExpansion

set _container_name=menv

docker rm --force %_container_name% > nul 2>&1
docker stop %_container_name% > nul 2>&1

docker build -t %_container_name% -f "%~dp0docker\Dockerfile" .

if %ERRORLEVEL% EQU 0 (
    docker run --name %_container_name% -it --rm %_container_name%
) else (
    echo Docker build failed.
)
