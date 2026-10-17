#requires -Version 5.1
# Standalone regression fixtures; no real apps are discovered or stopped.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Update-DiscordRules.ps1')
$session = [Diagnostics.Process]::GetCurrentProcess().SessionId
$root = 'C:\Fixture\Discord'
$inventory = @([pscustomobject]@{ Path = "$root\Discord.exe" })
$script:fixtures = @()
$script:stopped = @()

function Get-Process {
    param([string[]]$Name, $ErrorAction)
    @($script:fixtures | Where-Object { $_.ProcessName -in $Name })
}
function Stop-Process {
    param($InputObject, [switch]$Force, $ErrorAction)
    if (-not $InputObject.Path) { throw 'Attempted to stop an unverified process.' }
    $script:stopped += $InputObject.Id
    $InputObject.HasExited = $true
    $InputObject.Path = $null
}
function New-Fixture {
    param([string]$Name = 'Discord', [string]$Path, [bool]$Exited = $false)
    $fixture = [pscustomobject]@{
        ProcessName = $Name; Id = 1234; SessionId = $session
        Path = $Path; HasExited = $Exited
    }
    $fixture | Add-Member ScriptMethod CloseMainWindow { return $false }
    return $fixture
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$script:fixtures = @(New-Fixture -Exited $true)
Assert-True (@(Get-DiscordAppProcesses @($root) $inventory).Count -eq 0) 'Exited Discord must be ignored.'
Assert-AppsClosed @($root)

# Simulate Path disappearing while the enumeration snapshot is being examined.
$racing = New-Fixture
$racing.PSObject.Properties.Remove('Path')
$racing | Add-Member ScriptProperty Path { $this.HasExited = $true; return $null }
$script:fixtures = @($racing)
Assert-True (@(Get-DiscordAppProcesses @($root) $inventory).Count -eq 0) 'Process exiting during Path read must be ignored.'

$script:fixtures = @(New-Fixture)
$refused = $false
try { [void]@(Get-DiscordAppProcesses @($root) $inventory) }
catch { $refused = $_.Exception.Message -like '*PID 1234*' }
Assert-True $refused 'Unidentified live Discord must still be refused with its PID.'

$script:fixtures = @(New-Fixture -Name 'Update')
$updaterInventory = @([pscustomobject]@{ Path = "$root\Update.exe" })
$refused = $false
try { [void]@(Get-DiscordAppProcesses @($root) $updaterInventory -UpdatersOnly) }
catch { $refused = $_.Exception.Message -like '*PID 1234*' }
Assert-True $refused 'Unidentified live updater must still be refused.'

$script:fixtures = @(New-Fixture -Path 'C:\Other\Discord.exe')
Assert-True (@(Get-DiscordAppProcesses @($root) $inventory).Count -eq 0) 'Other installation must not be selected.'
$script:fixtures[0].Path = "$root\Discord.exe"
$script:fixtures[0].SessionId = $session + 1
Assert-True (@(Get-DiscordAppProcesses @($root) $inventory).Count -eq 0) 'Other Windows session must not be selected.'

$script:fixtures = @(New-Fixture -Name 'ProtonVPN.Client' -Exited $true)
Assert-True (@(Get-ProtonAppProcesses).Count -eq 0) 'Exited Proton must be ignored.'
Assert-AppsClosed @($root)

# A stopped process remains in the simulated enumeration with no image path.
# This reproduces the shutdown failure without stopping any real process.
$script:fixtures = @(New-Fixture -Path "$root\Discord.exe")
Close-AppGroup 'fixture Discord' { Get-DiscordAppProcesses @($root) $inventory }
Assert-True ($script:stopped.Count -eq 1) 'Verified live process should have been stopped once.'
Assert-AppsClosed @($root)
Write-Output 'PASS: shutdown races, live-path refusal, updater refusal, installation/session boundaries, and shutdown completion.'
