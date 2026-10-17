#requires -Version 5.1
[CmdletBinding()]
param([string]$SettingsPath, [switch]$AtSignIn)

. (Join-Path $PSScriptRoot 'Update-DiscordRules.ps1')

function Get-MonitorState {
    param([string]$AccountPath)
    $roots = @(Resolve-DiscordRoots)
    $inventory = @(Get-DiscordInventory $roots)
    $snapshot = Read-ProtonSettings $AccountPath
    $plan = New-DiscordRulePlan $snapshot $roots $inventory
    # Include all planned bytes so alternate-path and ordering changes count too.
    $signature = ''
    if ($plan.Changed) { $signature = [Convert]::ToBase64String($plan.Bytes) }
    return [pscustomobject]@{
        Changed = $plan.Changed
        Signature = $signature
        Message = ('Discord rules need updating: {0} to add, {1} to remove, {2} to enable. Open Janjanator and choose Refresh.' -f
            $plan.Added.Count, $plan.Removed.Count, $plan.Reactivated)
    }
}

function Show-MonitorNotification {
    param([string]$Title, [string]$Message)
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml('<toast activationType="foreground"><visual><binding template="ToastGeneric"><text></text><text></text></binding></visual></toast>')
    $nodes = $xml.GetElementsByTagName('text')
    $nodes.Item(0).InnerText = $Title
    $nodes.Item(1).InnerText = $Message
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    $toast.Tag = 'DiscordRules'
    $toast.Group = 'DiscordRuleUpdater'
    # The running monitor handles clicks directly, without asking Windows to
    # resolve a custom URL protocol. Keep the current toast alive for callbacks.
    $script:activeMonitorToast = $toast
    $guiPath = Join-Path $PSScriptRoot 'Discord-Rule-Updater-GUI.ps1'
    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $startInfo.Arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $guiPath + '"'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    # Compile a native .NET delegate: WinRT callbacks can arrive on threads
    # without a PowerShell runspace, and Register-ObjectEvent rejects WinRT.
    $eventType = $toast.GetType().GetEvent('Activated').EventHandlerType
    $parameters = @($eventType.GetMethod('Invoke').GetParameters() | ForEach-Object {
        [Linq.Expressions.Expression]::Parameter($_.ParameterType, $_.Name)
    })
    $startMethod = [Diagnostics.Process].GetMethod('Start', [type[]]@([Diagnostics.ProcessStartInfo]))
    $call = [Linq.Expressions.Expression]::Call($startMethod, [Linq.Expressions.Expression[]]@(
        [Linq.Expressions.Expression]::Constant($startInfo)))
    $body = [Linq.Expressions.Expression]::Block([Linq.Expressions.Expression[]]@($call, [Linq.Expressions.Expression]::Empty()))
    $script:toastClickHandler = [Linq.Expressions.Expression]::Lambda($eventType, $body,
        [Linq.Expressions.ParameterExpression[]]$parameters).Compile()
    $script:toastClickToken = $toast.add_Activated($script:toastClickHandler)
    $script:notifier.Show($toast)
}

function Register-MonitorShortcut {
    param([string]$AppId, [string]$AccountPath)
    # Desktop toasts require a Start-menu shortcut carrying the same AppUserModelID.
    if (-not ('DiscordMonitorShortcut' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DiscordMonitorShortcut {
    [StructLayout(LayoutKind.Sequential)]
    public struct PropertyKey { public Guid Format; public uint Id; }
    [StructLayout(LayoutKind.Explicit, Size = 24)]
    public struct PropVariant {
        [FieldOffset(0)] public ushort Type;
        [FieldOffset(8)] public IntPtr Value;
    }
    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore {
        void GetCount(out uint count);
        void GetAt(uint index, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant value);
        void SetValue(ref PropertyKey key, ref PropVariant value);
        void Commit();
    }
    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    static extern void SHGetPropertyStoreFromParsingName(string path, IntPtr context,
        uint flags, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);
    public static void SetAppId(string path, string appId) {
        var iid = typeof(IPropertyStore).GUID;
        IPropertyStore store;
        SHGetPropertyStoreFromParsingName(path, IntPtr.Zero, 2, ref iid, out store);
        var key = new PropertyKey { Format = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), Id = 5 };
        var value = new PropVariant { Type = 31, Value = Marshal.StringToCoTaskMemUni(appId) };
        try { store.SetValue(ref key, ref value); store.Commit(); }
        finally { Marshal.FreeCoTaskMem(value.Value); Marshal.ReleaseComObject(store); }
    }
}
'@
    }
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'Janjanator Monitor.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $null
    try {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' +
            (Join-Path $PSScriptRoot 'Watch-DiscordRules.ps1') + '" -SettingsPath "' + $AccountPath + '"'
        $shortcut.WorkingDirectory = $PSScriptRoot
        $shortcut.Description = 'Check Discord VPN rules once a minute'
        $shortcut.IconLocation = (Join-Path $PSScriptRoot 'Assets\App.ico') + ',0'
        $shortcut.WindowStyle = 7
        $shortcut.Save()
    } finally {
        if ($shortcut) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) }
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
    [DiscordMonitorShortcut]::SetAppId($shortcutPath, $AppId)
}

function Get-MonitorNotificationPermission {
    param([object]$Notifier)
    try { return [string]$Notifier.get_Setting() }
    catch {
        # Some Windows builds cannot query a newly registered desktop sender.
        # This is not proof that notifications are disabled; let Show attempt
        # delivery and retain the visible tray fallback if delivery fails.
        $exception = $_.Exception
        while ($exception) {
            if ($exception.HResult -eq -2147023728) { return 'Unknown' } # 0x80070490
            $exception = $exception.InnerException
        }
        throw
    }
}

function Register-MonitorActivation {
    # A fixed per-user protocol opens only our GUI. URI input is never passed
    # to PowerShell, so notification activation cannot inject script arguments.
    $protocolPath = 'HKCU:\Software\Classes\discord-proton-updater'
    [void](New-Item -Path $protocolPath -Force)
    Set-Item -Path $protocolPath -Value 'URL:Janjanator'
    [void](New-ItemProperty -Path $protocolPath -Name 'URL Protocol' -Value '' -PropertyType String -Force)
    $commandPath = $protocolPath + '\shell\open\command'
    [void](New-Item -Path $commandPath -Force)
    $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $guiPath = Join-Path $PSScriptRoot 'Discord-Rule-Updater-GUI.ps1'
    $command = '"' + $powershellPath + '" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $guiPath + '"'
    Set-Item -Path $commandPath -Value $command
}

if ($MyInvocation.InvocationName -ne '.') {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $tray = $null
    $timer = $null
    $mutex = New-Object Threading.Mutex($false, 'Local\DiscordProtonRuleMonitor')
    $owned = $false
    try {
        try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
        if (-not $owned) {
            if ($AtSignIn) { return }
            throw 'The Janjanator monitor is already running. Look for its icon in the Windows system tray.'
        }
        $SettingsPath = Resolve-ProtonSettingsPath $SettingsPath
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        # Register a per-user sender so portable installations do not depend on
        # a PowerShell Start-menu shortcut being present on this computer.
        $appId = 'DiscordProtonRuleUpdater.Monitor'
        $registration = 'HKCU:\Software\Classes\AppUserModelId\' + $appId
        [void](New-Item -Path $registration -Force)
        [void](New-ItemProperty -Path $registration -Name DisplayName -Value 'Janjanator' -PropertyType String -Force)
        [void](New-ItemProperty -Path $registration -Name ShowInSettings -Value 1 -PropertyType DWord -Force)
        [void](New-ItemProperty -Path $registration -Name IconUri -Value (Join-Path $PSScriptRoot 'Assets\App.ico') -PropertyType String -Force)
        Register-MonitorShortcut $appId $SettingsPath
        $script:notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
        $permission = Get-MonitorNotificationPermission $script:notifier
        if ($permission -ne 'Enabled' -and $permission -ne 'Unknown') {
            throw 'Windows notifications for Janjanator are disabled. Enable them in Windows Settings > System > Notifications, then try again.'
        }
        $script:lastMonitorSignature = ''
        $tray = New-Object Windows.Forms.NotifyIcon
        $tray.Icon = New-Object Drawing.Icon((Join-Path $PSScriptRoot 'Assets\App.ico'))
        $tray.Text = 'Janjanator: checking every minute'
        $menu = New-Object Windows.Forms.ContextMenuStrip
        $open = $menu.Items.Add('Open Janjanator')
        $open.Add_Click({
            $launchArgs = '-NoProfile -ExecutionPolicy Bypass -STA -File "' + (Join-Path $PSScriptRoot 'Discord-Rule-Updater-GUI.ps1') + '"'
            Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $launchArgs -WindowStyle Hidden
        })
        $stop = $menu.Items.Add('Stop monitoring')
        $stop.Add_Click({ [Windows.Forms.Application]::ExitThread() })
        $tray.ContextMenuStrip = $menu
        $tray.Visible = $true
        $timer = New-Object Windows.Forms.Timer
        $timer.Interval = 60000
        $timer.Add_Tick({
            $timer.Stop()
            try {
                try {
                    $state = Get-MonitorState $SettingsPath
                    $signature = $state.Signature
                    $title = 'Janjanator: rules need attention'
                    $message = $state.Message
                    $tray.Text = 'Janjanator: up to date'
                    if ($state.Changed) { $tray.Text = 'Janjanator: refresh needed' }
                } catch {
                    $signature = 'Error: ' + $_.Exception.Message
                    $title = 'Janjanator monitor needs attention'
                    $message = $_.Exception.Message + ' Open the updater and choose Diagnose.'
                    $tray.Text = 'Janjanator: check could not complete'
                }
                if ($signature -and $signature -cne $script:lastMonitorSignature) {
                    Show-MonitorNotification $title $message
                }
                $script:lastMonitorSignature = $signature
            } catch {
                $tray.Text = 'Janjanator: notifications unavailable'
                $tray.ShowBalloonTip(10000, 'Notification could not be sent', $_.Exception.Message, [Windows.Forms.ToolTipIcon]::Error)
            } finally { $timer.Start() }
        })
        $timer.Start()
        [Windows.Forms.Application]::Run()
    } catch {
        [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Janjanator monitor', 'OK', 'Warning')
        exit 1
    } finally {
        if ($timer) { $timer.Stop(); $timer.Dispose() }
        if ($tray) { $tray.Visible = $false; $tray.Dispose() }
        if ($owned) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}
