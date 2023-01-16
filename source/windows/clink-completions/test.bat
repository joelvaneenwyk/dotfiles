@echo off
if exist "C:\Windows\System32\chcp.com" call "C:\Windows\System32\chcp.com" 65001 1>nul
luacheck . && busted
