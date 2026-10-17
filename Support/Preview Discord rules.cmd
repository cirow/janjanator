@echo off
echo Janjanator - shareable v4
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-DiscordRules.ps1" -ChooseAccount
pause
