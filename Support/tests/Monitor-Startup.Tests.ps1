#requires -Version 5.1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Monitor-Startup.ps1')
$script:realStartup = [Environment]::GetFolderPath('Startup')
$script:fixtureFolder = Join-Path $PSScriptRoot ('startup-fixture-' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($script:fixtureFolder)
# Redirect only the Startup-folder path to an isolated fixture; no real startup
# shortcut is created or removed. Other paths use normal PowerShell behavior.
function Join-Path {
    param([string]$Path, [string]$ChildPath)
    if ($Path -eq $script:realStartup) { $Path = $script:fixtureFolder }
    Microsoft.PowerShell.Management\Join-Path -Path $Path -ChildPath $ChildPath
}
try {
    if (Get-MonitorStartupEnabled) { throw 'Expected disabled initially.' }
    $accountFixture = Microsoft.PowerShell.Management\Join-Path $PSScriptRoot '..\VERSION.txt'
    Set-MonitorStartup -Enabled $true -AccountPath $accountFixture
    if (-not (Get-MonitorStartupEnabled)) { throw 'Startup shortcut missing.' }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $script:fixtureFolder 'Janjanator Monitor.lnk'))
    try {
        if ($shortcut.Arguments -notlike '*-SettingsPath "*VERSION.txt" -AtSignIn') { throw 'Saved account or startup flag missing.' }
        if ($shortcut.TargetPath -notlike '*\powershell.exe') { throw 'Wrong startup program.' }
        if ($shortcut.Arguments -notlike '*-WindowStyle Hidden*') { throw 'Startup should hide the console.' }
    } finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut)
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
    Set-MonitorStartup -Enabled $false
    Set-MonitorStartup -Enabled $false
    if (Get-MonitorStartupEnabled) { throw 'Startup still enabled.' }
    $refused = $false
    try { Set-MonitorStartup -Enabled $true -AccountPath '' } catch { $refused = $true }
    if (-not $refused) { throw 'Empty account should be rejected.' }
    Write-Output 'PASS: startup enable/disable, saved account, hidden launch, and missing-account refusal (isolated shortcut).'
} finally {
    # Remove only the empty fixture directory created by this test.
    Set-MonitorStartup -Enabled $false
    [IO.Directory]::Delete($script:fixtureFolder)
}
