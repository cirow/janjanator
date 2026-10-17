#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'Build.ps1')
$releaseFolder = Join-Path $root 'Releases'
[void][IO.Directory]::CreateDirectory($releaseFolder)
$files = @(
    'Janjanator.exe',
    'Support/Assets/App.ico', 'Support/Assets/App.png',
    'Support/Launcher.cs', 'Support/Build.ps1', 'Support/Package.ps1',
    'Support/BUILD.md', 'Support/README.md', 'Support/START HERE.txt',
    'Support/VERSION.txt', 'Support/VALIDATION.md',
    'Support/Discord-Rule-Updater-GUI.ps1', 'Support/Update-DiscordRules.ps1',
    'Support/Watch-DiscordRules.ps1', 'Support/Monitor-Startup.ps1', 'Support/Janjanator.cmd',
    'Support/Preview Discord rules.cmd', 'Support/Refresh Discord rules.cmd',
    'Support/Diagnose Proton settings.cmd', 'Support/tests/Shutdown-Races.Tests.ps1',
    'Support/tests/Monitor-Startup.Tests.ps1'
)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($relative in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
        throw ('Missing release file: ' + $relative)
    }
}
$zipPath = Join-Path $releaseFolder 'Janjanator.zip'
$stream = [IO.File]::Open($zipPath, [IO.FileMode]::Create)
$archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relative in $files) {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,
            (Join-Path $root $relative), $relative, [IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $archive.Dispose(); $stream.Dispose() }
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText(($zipPath + '.sha256'), ($hash + '  Janjanator.zip' + "`r`n"), (New-Object Text.UTF8Encoding($false)))
Write-Host ('Release ready: ' + $zipPath) -ForegroundColor Green
