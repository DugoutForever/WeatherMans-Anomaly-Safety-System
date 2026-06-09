@echo off
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0..\src\Anomaly_Safety_System_v1_10.ps1"
echo.
pause
