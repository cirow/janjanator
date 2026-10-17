@echo off
echo Janjanator - shareable v4
echo This closes Discord and Proton VPN, refreshes Discord's Included apps,
echo and reopens Proton VPN. Reconnect Proton before reopening Discord.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-DiscordRules.ps1" -Apply -CloseApps -OpenProton -ChooseAccount
if errorlevel 1 echo REFRESH DID NOT COMPLETE. Read the error and failed stage above.
pause
