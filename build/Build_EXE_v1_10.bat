@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_EXE_v1_10.ps1"
echo.
pause
