@echo off
echo Janjanator - shareable v4
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-DiscordRules.ps1" -Diagnose > "%~dp0Diagnostic report.txt" 2>&1
type "%~dp0Diagnostic report.txt"
echo Report saved beside this command as Diagnostic report.txt.
pause
