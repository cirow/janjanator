@echo off
if not exist "%~dp0Discord-Rule-Updater-GUI.ps1" (
    echo The Support folder is missing. Extract the complete ZIP, then try again.
    pause
    exit /b 1
)
start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0Discord-Rule-Updater-GUI.ps1"
