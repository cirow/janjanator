# Janjanator for Proton VPN — shareable Windows edition

Each person can use this same package on their own PC. The script reads their
Windows environment folders; it contains no fixed username, PC name, Proton
account ID, or Discord version. The package includes no saved account settings
or backups.

## Quick start

Click **Start monitor** to check the selected account once a minute, starting
after one minute. A Windows notification appears when rules need refreshing or a
check cannot complete. Unchanged results stay quiet; after rules become current,
new changes can notify again. Monitoring uses the same read-only plan as Preview
and never closes apps or writes Proton settings.

The monitor keeps running when the interface closes. Right-click its system-tray
icon to open the updater or **Stop monitoring**. It does not start with Windows.
On first launch, the monitor registers **Janjanator** as a notification
sender for the current Windows user (no administrator access or startup task).
It also creates a **Janjanator Monitor** Start-menu shortcut with the
matching notification identity required by Windows. This shortcut does not run
at login; starting the monitor remains optional.
Clicking the latest monitor notification opens the updater interface through
the running monitor. Keep the monitor running for click handling. Clicking a
notification never applies changes automatically.
Enable its notifications in Windows Settings. Do Not Disturb can silence banners; check the
Windows notification center. If Windows rejects a notification, the tray icon
shows a notification error. Only one monitor runs per Windows session.

Advanced use: run `Support\Watch-DiscordRules.ps1 -SettingsPath 'C:\path\UserSettings.account.json'`
with Windows PowerShell. Omit SettingsPath only when one Proton account exists.

For a graphical interface, double-click **Janjanator.exe**. Preview,
Refresh, and Diagnose appear on the left, with live output on the right. If
multiple Proton account files exist, Preview and Refresh open an account picker.
Buttons are disabled during an action; wait for it to finish before closing the
window. Diagnose saves `Diagnostic report.txt` inside `Support`.
The main folder contains just **Janjanator.exe** and the **Support**
folder. Keep them together. Scripts, documentation, tests, and optional console
launchers are inside `Support`; users only need the main launcher.

Output uses green for rules to add or enable, red for rules to remove, cyan
for section headings, and yellow for next steps. Text labels also identify each
action in plain-text reports. The summary shows how many rules will be added
and removed before any changes are saved.
Long lines wrap to fit the graphical output panel. Each output line has a
number on the left; wrapped continuations align with the text under that number.
Numbering restarts for each action; saved reports keep the original text.

1. Install and sign in to the **Windows desktop** apps for Discord and Proton VPN.
2. In Proton, enable **Split tunneling → Include mode** and apply that setting.
3. Extract the ZIP and keep its files together. Run the tool while signed into
   the Windows account that owns the Discord/Proton installations.
4. After Discord updates, open **Janjanator.exe** and click **Refresh**.
   If multiple account files are found, select the one you use in the picker.
   Apps stay open until this selection and the
   setup checks finish. Choosing a file that needs Include setup stops the refresh.
5. **Reconnect Proton**, then reopen Discord. Reconnect even if Proton initially
   still shows Connected so the revised rules are loaded.

The **Preview** button shows proposed changes without editing settings
or closing apps. The refresh command requests a normal close for Discord and
Proton's client. After five seconds, it ends any remaining verified app
processes. This ends active Discord calls. It leaves Proton's VPN services
running, so closing the client does not guarantee a VPN disconnection.

In v4, Proton is explicitly launched with its installation folder as the working
directory. Older launches could leave the updater folder as Proton's working
directory, preventing Windows from deleting that folder while Proton remained
open. To remove an already locked older copy, exit Proton from its tray icon,
then retry deletion. The startup fix takes effect on the next launch from v4.

If a Discord updater is busy, it waits up to 30 seconds, then cancels rather
than terminating the updater. Wait until the update finishes and retry. Proton
is reopened after refresh; Discord remains closed until you reopen it.

## What it finds and changes

The standard Discord, Discord PTB, and Discord Canary folders are discovered
under the current user's `%LOCALAPPDATA%`. A running Discord process in the same
Windows session can also identify a custom installation folder named `Discord`,
`DiscordPTB`, or `DiscordCanary`. Every executable inside those
installation folders is included and enabled. Missing paths within those
folders are removed; installed older versions remain included while their files
exist. Other app entries, external installers, and other preferences are kept.

The newest client is found under `%ProgramFiles%\Proton\VPN\v<version>`. There
is no fixed Proton version in the script. The settings file is discovered under:

```text
%LOCALAPPDATA%\Proton\Proton VPN\Storage\UserSettings.<account-id>.json
```

The tool expects the settings format with `SplitTunnelingInverseAppsList`,
`IsSplitTunnelingEnabled`, and `SplitTunnelingMode = Inverse`, as checked with
Proton VPN 5.1.8. An older/future Proton build with a different format will be
rejected. Compatibility with every Proton version is not promised. This is an
unofficial utility that edits Proton's internal settings format.

Windows PowerShell 5.1 and PowerShell 7 are supported. The launchers use the
built-in Windows PowerShell. Normally no administrator access is needed. Their
ExecutionPolicy Bypass flag applies only to that process and does not change
the computer's saved execution policy.

## Multiple accounts or custom folders

The console commands and examples below are for advanced use from inside the
`Support` folder. For everyday use, open the main launcher and use its buttons.

If more than one Proton account settings file is found, the launchers show a
numbered list before closing apps or editing settings. They display filenames,
the last saved times, and whether Include mode is ready. Enter the intended file's
number, or press Enter to cancel. The script does not guess or change every account.
If you cannot identify your account: cancel, open Proton, Apply your Include
settings, and rerun. Compare the updated saved time in the list.

The PowerShell script's `-ChooseAccount` option enables this selector. You can
also choose the intended account file explicitly from this folder:

```powershell
.\Update-DiscordRules.ps1 -SettingsPath 'C:\path\UserSettings.account.json' `
    -Apply -CloseApps -OpenProton
```

Custom Discord installations can be specified. The installation folder must be
named `Discord`, `DiscordPTB`, or `DiscordCanary`:

```powershell
.\Update-DiscordRules.ps1 -DiscordRoot 'D:\Apps\Discord' `
    -Apply -CloseApps -OpenProton
```

For a Proton client installed outside the standard Proton folder, automatic
close/reopen is not supported. Exit both apps manually, run the following, then
open Proton yourself and reconnect:

```powershell
.\Update-DiscordRules.ps1 -Apply
```

The script refuses unknown formats, linked installation folders, incomplete
scans, ambiguous/mixed alternate app paths, or settings/files that change during
the refresh. It verifies executable paths and the Windows session before
automatically stopping app processes, avoiding unrelated `Update.exe` apps.

## Backup and restore

An exact backup is created on each actual change in `DiscordRuleBackups` beside
the account settings file. The exact path is printed. Preview and no-op runs
create no backup. Keep these backups private; they contain the user's settings.

To undo: disconnect and exit Proton, copy the printed backup over the original
`UserSettings.<account-id>.json`, then reopen and reconnect Proton. A full-file
restore also restores other preferences to their state when the backup was made.

## Account-file detection errors

The previous "Expected exactly one" error could mean either zero files or several
files. This version gives different messages for those situations, accepts
`UserSettings.json` as well as account-suffixed `UserSettings.*.json`, and checks
two alternate named Proton Storage folders if the current folder contains no
account files. The settings layout is still validated before changing anything.

If no account file is found, open Proton, sign in, enable Include mode, and Apply
before retrying. If the error continues, run **Diagnose Proton settings.cmd**.
It reports the current Windows profile, searched folders, file names, saved
times, and basic compatibility status. It never closes apps or writes settings.
It does not show file contents, passwords, or tokens. Its output contains local
paths and file identifiers; share only that output if you need troubleshooting,
not the actual settings files.

Different Proton versions or an elevated launch under a different Windows
account can require further diagnosis. A different settings layout is rejected
instead of being rewritten as though it were compatible.

## Scope of automation

The list is refreshed when the command runs. No scheduled task or background
service is installed. The script does not automatically connect the VPN, open
Discord, or verify traffic routing. If Discord updates again while launching,
run another refresh after the update finishes. Use the full VPN while updating
if the update and first launch need to remain inside the VPN.

## Checking an incomplete refresh

The console shows the account-selection, setup-check, shutdown, and update
stages. A successful refresh prints `Shutdown verified` and `Refresh completed`
with the number of discovered Discord executable rules. Proton reopens at the
end by design, so its being open afterward does not mean it was never closed.

If apps stay open and rules are missing, leave both apps open and run **Diagnose
Proton settings.cmd**. It saves `Diagnostic report.txt` beside the command and
displays it. The report shows visible app process/image paths, account-file
status, scan folders, and the complete executable inventory. It reads metadata
and writes the report only; it does not close apps or change Proton settings.
Share the report and the last console lines from the failed Refresh, plus the
full path of an executable that was missed. Keep actual settings/backups private.

The scan covers discovered installation folders, including helpers inside them.
Downloaded installers, installations belonging to other Windows accounts, and
custom folders whose location cannot be verified require separate identification.
For a custom install that is not running, use `-DiscordRoot` as described above.

The same ZIP can be shared as-is. Share this package, not anything from the
Proton storage/backup folders. See `VALIDATION.md` for the testing scope.
