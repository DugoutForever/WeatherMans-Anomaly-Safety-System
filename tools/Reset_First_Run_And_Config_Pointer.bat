@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reset_First_Run_And_Config_Pointer.ps1"
endlocal
pause
