#requires -Version 5.1
# Dot-source these helpers; they change startup only when the user enables it.
function Get-MonitorStartupEnabled {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Janjanator Monitor.lnk'
    return (Test-Path -LiteralPath $shortcutPath -PathType Leaf)
}

function Set-MonitorStartup {
    param([bool]$Enabled, [string]$AccountPath)
    $startupFolder = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startupFolder 'Janjanator Monitor.lnk'
    if (-not $Enabled) {
        if (Get-MonitorStartupEnabled) {
            Remove-Item -LiteralPath $shortcutPath -ErrorAction Stop
        }
        return
    }
    if ([string]::IsNullOrWhiteSpace($AccountPath) -or -not (Test-Path -LiteralPath $AccountPath -PathType Leaf)) {
        throw 'Choose an existing Proton account settings file before enabling startup.'
    }
    $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $monitorPath = Join-Path $PSScriptRoot 'Watch-DiscordRules.ps1'
    $arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' +
        $monitorPath + '" -SettingsPath "' + $AccountPath + '" -AtSignIn'
    [void][IO.Directory]::CreateDirectory($startupFolder)
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $null
    try {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $powershellPath
        $shortcut.Arguments = $arguments
        $shortcut.WorkingDirectory = $PSScriptRoot
        $shortcut.IconLocation = (Join-Path $PSScriptRoot 'Assets\App.ico') + ',0'
        $shortcut.Description = 'Start the Janjanator rule monitor when you sign in'
        $shortcut.WindowStyle = 7
        $shortcut.Save()
    } finally {
        if ($shortcut) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
}
