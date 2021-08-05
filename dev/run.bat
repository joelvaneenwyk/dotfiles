@echo off

docker build -t menv -f "%~dp0Dockerfile" "%~dp0.."
docker rm menv
docker run --name menv -it --rm menv
