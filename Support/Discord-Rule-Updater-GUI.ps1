#requires -Version 5.1
# The existing updater runs in a separate process so scans and shutdown waits
# never block the interface. No app action runs until a button is pressed.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$ErrorActionPreference = 'Stop'
$updaterPath = Join-Path $PSScriptRoot 'Update-DiscordRules.ps1'
. $updaterPath

$script:job = $null
$script:reportLines = New-Object 'System.Collections.Generic.List[string]'
$form = New-Object Windows.Forms.Form
$form.Text = 'Janjanator for Proton VPN'
$appIconPath = Join-Path $PSScriptRoot 'Assets\App.ico'
if (Test-Path -LiteralPath $appIconPath) { $form.Icon = New-Object Drawing.Icon($appIconPath) }
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object Drawing.Size(1000, 620)
$form.MinimumSize = New-Object Drawing.Size(800, 480)
$form.Font = New-Object Drawing.Font('Segoe UI', 10)
$form.BackColor = [Drawing.Color]::FromArgb(245, 246, 248)

$layout = New-Object Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'
$layout.Padding = New-Object Windows.Forms.Padding(20)
$layout.ColumnCount = 2
$layout.RowCount = 1
[void]$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute', 220)))
[void]$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent', 100)))
$form.Controls.Add($layout)

$sidebar = New-Object Windows.Forms.FlowLayoutPanel
$sidebar.Dock = 'Fill'
$sidebar.FlowDirection = 'TopDown'
$sidebar.WrapContents = $false
$layout.Controls.Add($sidebar, 0, 0)
$title = New-Object Windows.Forms.Label
$title.Text = 'Janjanator'
$title.Font = New-Object Drawing.Font('Segoe UI', 17, [Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Margin = New-Object Windows.Forms.Padding(0, 0, 0, 8)
$sidebar.Controls.Add($title)
$subtitle = New-Object Windows.Forms.Label
$subtitle.Text = "Proton VPN Include mode`r`nChoose an action to begin."
$subtitle.Size = New-Object Drawing.Size(200, 60)
$sidebar.Controls.Add($subtitle)

$script:buttons = @()
foreach ($action in @('Preview', 'Refresh', 'Diagnose', 'Start monitor')) {
    $button = New-Object Windows.Forms.Button
    $button.Text = $action
    $button.Tag = $action
    $button.Size = New-Object Drawing.Size(195, 48)
    $button.Margin = New-Object Windows.Forms.Padding(0, 0, 12, 12)
    $button.Add_Click({ Start-UpdaterAction ([string]$this.Tag) })
    $sidebar.Controls.Add($button)
    $script:buttons += $button
}
$hint = New-Object Windows.Forms.Label
$hint.Text = "Refresh closes Discord and Proton's client. Active calls will end.`r`n`r`nAfter refreshing, reconnect Proton before reopening Discord."
$hint.Size = New-Object Drawing.Size(195, 170)
$hint.ForeColor = [Drawing.Color]::FromArgb(80, 86, 96)
$sidebar.Controls.Add($hint)

$right = New-Object Windows.Forms.TableLayoutPanel
$right.Dock = 'Fill'
$right.ColumnCount = 1
$right.RowCount = 2
[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute', 32)))
[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle('Percent', 100)))
$layout.Controls.Add($right, 1, 0)
$status = New-Object Windows.Forms.Label
$status.Text = 'Ready'
$status.Dock = 'Fill'
$right.Controls.Add($status, 0, 0)
$output = New-Object Windows.Forms.RichTextBox
$output.Dock = 'Fill'
$output.ReadOnly = $true
$output.WordWrap = $true
$output.ScrollBars = 'Vertical'
$output.DetectUrls = $false
$output.BackColor = [Drawing.Color]::FromArgb(24, 28, 36)
$output.ForeColor = [Drawing.Color]::FromArgb(225, 230, 238)
$output.Font = New-Object Drawing.Font('Consolas', 10)
$output.BorderStyle = 'None'
$output.Text = "Output will appear here.`r`n`r`nPreview shows proposed rules. Refresh applies them. Diagnose saves a report beside this interface."
$right.Controls.Add($output, 0, 1)
$script:outputLineNumber = 0

function Add-ConsoleLine {
    param([string]$Line)
    $color = $output.ForeColor
    if ($Line.StartsWith([string][char]0x2705) -or $Line -match '^ADD\s|^ENABLE\s|^\s*Rules to add:|^Already current\.|^Discord Included apps refreshed\.|^Refresh completed\.') {
        $color = [Drawing.Color]::FromArgb(118, 220, 145)
    } elseif ($Line.StartsWith([string][char]0x274C) -or $Line -match '^REMOVE\s|^\s*Rules to remove:|^REFRESH FAILED|^Error:|^Output/report error:') {
        $color = [Drawing.Color]::FromArgb(255, 125, 125)
    } elseif ($Line -match '^--- |^Rule summary$') {
        $color = [Drawing.Color]::FromArgb(110, 205, 240)
    } elseif ($Line -match '^Preview only\.|^Proton reopened\.|^Open Proton and reconnect|^Next step:') {
        $color = [Drawing.Color]::FromArgb(245, 210, 120)
    }
    $output.SelectionStart = $output.TextLength
    $output.SelectionLength = 0
    $script:outputLineNumber++
    $prefix = ('{0,4} | ' -f $script:outputLineNumber)
    # Wrapped continuations align with the text, leaving numbers on the left.
    $prefixWidth = [Windows.Forms.TextRenderer]::MeasureText($prefix, $output.Font,
        [Drawing.Size]::Empty, [Windows.Forms.TextFormatFlags]::NoPadding).Width
    $output.SelectionIndent = 0
    $output.SelectionHangingIndent = $prefixWidth
    $output.SelectionRightIndent = 10
    $output.SelectionColor = [Drawing.Color]::FromArgb(145, 155, 170)
    $output.AppendText($prefix)
    $output.SelectionColor = $color
    $output.AppendText($Line + "`r`n")
    $output.SelectionColor = $output.ForeColor
    $output.SelectionStart = $output.TextLength
    $output.ScrollToCaret()
}

function Select-GuiAccount {
    $files = @(Find-ProtonSettingsFiles | Sort-Object LastWriteTimeUtc -Descending)
    if ($files.Count -eq 0) { return (Resolve-ProtonSettingsPath) }
    if ($files.Count -eq 1) { return $files[0].FullName }
    $dialog = New-Object Windows.Forms.Form
    $dialog.Text = 'Choose your Proton account settings'
    $dialog.StartPosition = 'CenterParent'
    $dialog.ClientSize = New-Object Drawing.Size(760, 300)
    $dialog.Font = $form.Font
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $help = New-Object Windows.Forms.Label
    $help.Text = 'Select your account. If unsure, cancel, apply Include settings in Proton, and compare saved times.'
    $help.SetBounds(12, 12, 730, 40)
    $dialog.Controls.Add($help)
    $list = New-Object Windows.Forms.ListBox
    $list.SetBounds(12, 56, 730, 180)
    $list.HorizontalScrollbar = $true
    foreach ($file in $files) {
        $state = 'Needs Include setup or unsupported format'
        try { [void](Read-ProtonSettings $file.FullName); $state = 'Include mode ready' } catch { }
        [void]$list.Items.Add(('{0} | Saved {1} | {2} | {3}' -f $file.Name,
            $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'), $state, $file.DirectoryName))
    }
    $dialog.Controls.Add($list)
    $ok = New-Object Windows.Forms.Button
    $ok.Text = 'Select'
    $ok.SetBounds(548, 252, 94, 32)
    $ok.Enabled = $false
    $ok.DialogResult = 'OK'
    $dialog.Controls.Add($ok)
    $cancel = New-Object Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.SetBounds(648, 252, 94, 32)
    $cancel.DialogResult = 'Cancel'
    $dialog.Controls.Add($cancel)
    $dialog.AcceptButton = $ok
    $dialog.CancelButton = $cancel
    $list.Add_SelectedIndexChanged({ $ok.Enabled = $list.SelectedIndex -ge 0 })
    try {
        if ($dialog.ShowDialog($form) -ne [Windows.Forms.DialogResult]::OK) { return $null }
        return $files[$list.SelectedIndex].FullName
    } finally { $dialog.Dispose() }
}

function Start-UpdaterAction {
    param([string]$Action)
    if ($null -ne $script:job) { return }
    $output.Clear()
    $script:outputLineNumber = 0
    $script:reportLines.Clear()
    $status.Text = $Action + ' - preparing...'
    try {
        if ($Action -eq 'Start monitor') {
            $account = Select-GuiAccount
            if (-not $account) { $status.Text = 'Cancelled'; return }
            $monitorArgs = '-NoProfile -ExecutionPolicy Bypass -STA -File "' +
                (Join-Path $PSScriptRoot 'Watch-DiscordRules.ps1') + '" -SettingsPath "' + $account + '"'
            Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $monitorArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
            $status.Text = 'Monitor launch requested - look for its tray icon'
            Add-ConsoleLine 'The monitor checks once a minute and notifies you when rules need attention.'
            Add-ConsoleLine 'It stays running after this window closes. Right-click its tray icon and choose Stop monitoring to exit.'
            return
        }
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $updaterPath + '"'
        if ($Action -eq 'Diagnose') { $arguments += ' -Diagnose' }
        else {
            $account = Select-GuiAccount
            if (-not $account) {
                $status.Text = 'Cancelled'
                Add-ConsoleLine 'Account selection cancelled. No apps were closed and no settings were changed.'
                return
            }
            $arguments += ' -SettingsPath "' + $account + '"'
            if ($Action -eq 'Refresh') { $arguments += ' -Apply -CloseApps -OpenProton' }
        }
        $info = New-Object Diagnostics.ProcessStartInfo
        $info.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $info.Arguments = $arguments
        $info.WorkingDirectory = $PSScriptRoot
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
        $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
        $process = New-Object Diagnostics.Process
        $process.StartInfo = $info
        [void]$process.Start()
        $script:job = @{
            Process = $process; Action = $Action
            OutTask = $process.StandardOutput.ReadLineAsync()
            ErrTask = $process.StandardError.ReadLineAsync()
        }
        foreach ($button in $script:buttons) { $button.Enabled = $false }
        $status.Text = $Action + ' - running...'
        $timer.Start()
    } catch {
        $status.Text = 'Could not start ' + $Action
        Add-ConsoleLine ([string][char]0x274C + ' Could not start: ' + $_.Exception.Message)
    }
}

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    try {
        foreach ($stream in @('Out', 'Err')) {
            $key = $stream + 'Task'
            # Limit each tick so a large inventory cannot starve UI messages.
            for ($i = 0; $i -lt 100; $i++) {
                $task = $script:job[$key]
                if ($null -eq $task -or -not $task.IsCompleted) { break }
                $line = $task.GetAwaiter().GetResult()
                if ($null -eq $line) { $script:job[$key] = $null; break }
                Add-ConsoleLine $line
                $script:reportLines.Add($line)
                if ($stream -eq 'Out') { $script:job[$key] = $script:job.Process.StandardOutput.ReadLineAsync() }
                else { $script:job[$key] = $script:job.Process.StandardError.ReadLineAsync() }
            }
        }
        if ($script:job.Process.HasExited -and $null -eq $script:job.OutTask -and $null -eq $script:job.ErrTask) {
            $timer.Stop()
            $exitCode = $script:job.Process.ExitCode
            $action = $script:job.Action
            $script:job.Process.Dispose()
            $script:job = $null
            foreach ($button in $script:buttons) { $button.Enabled = $true }
            if ($exitCode -eq 0) { $status.Text = [string][char]0x2705 + ' ' + $action + ' completed' }
            else { $status.Text = [string][char]0x274C + ' ' + $action + ' failed - see output' }
            if ($action -eq 'Diagnose') {
                $report = Join-Path $PSScriptRoot 'Diagnostic report.txt'
                [IO.File]::WriteAllLines($report, $script:reportLines.ToArray(), (New-Object Text.UTF8Encoding($true)))
                Add-ConsoleLine ('Report saved: ' + $report)
            }
        }
    } catch {
        # Continue draining a running child; never terminate it during a settings write.
        Add-ConsoleLine ([string][char]0x274C + ' Output/report error: ' + $_.Exception.Message)
        if ($null -eq $script:job) { $timer.Stop(); $status.Text = 'Report could not be saved - see output' }
    }
})
$form.Add_FormClosing({
    if ($null -ne $script:job) {
        $_.Cancel = $true
        Add-ConsoleLine 'Please wait for the current action to finish before closing.'
    }
})
try { [void]$form.ShowDialog() }
finally { $timer.Dispose(); $form.Dispose() }
