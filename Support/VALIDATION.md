# Shareable edition validation

Shutdown-race regression fixtures (`tests/Shutdown-Races.Tests.ps1`) passed in
Windows PowerShell 5.1 and PowerShell 7. They cover an exited process remaining
in an enumeration snapshot, exit during image-path inspection, refusal of live
Discord/updaters with unreadable paths, installation/session boundaries, exited
Proton clients, and completion after a simulated force-stop. Process discovery
and stopping are mocked; no real apps or Proton settings are changed.

The optional Windows Forms interface was smoke-tested in Windows PowerShell 5.1
using a harmless child script. Checks covered form/control layout, stdout and
stderr capture, completion status, and disabling/restoring action buttons.
This check did not close Discord/Proton or change Proton settings. The account
picker and real refresh workflow have not been exercised end to end in the GUI.

V4 adds an explicit Proton installation working directory to both normal and
failure-recovery launches. The 9 app-close/reopen fixture checks were rerun in
Windows PowerShell 5.1 and PowerShell 7, with the launch mock rejecting any other
working directory. They passed. No real Proton process was stopped or restarted
during this validation. The following broader results are from the v3 core:

The v3 script passed 35 offline checks in Windows PowerShell 5.1 and PowerShell
7: 13 settings/backup checks, 9 automatic-close checks, 9 account detection
and selection checks, and 4 running-installation discovery/diagnostic checks.
The settings/close tests were rerun against this version.
They cover preservation, backups/restoration, concurrent edits, and simulated
application shutdown/reopening.

New account tests verify distinct zero/multiple-file messages, filenames without
an account suffix, fallback Storage folders, precedence for current Storage,
numbered selection, cancellation/invalid input, explicit SettingsPath, updating
only the selected account, and read-only diagnostics that do not expose file
contents even when JSON parsing fails. An unselected account stayed byte-for-byte
unchanged during a full fixture refresh.

The discovery tests verified a running custom Discord folder with spaces and
brackets in its path, helper discovery, exclusion of other Windows sessions and
unverifiable folders, explicit-root behavior, and diagnostic process/inventory
output.

A native shutdown probe also passed in Windows PowerShell 5.1. Harmless copies
of Windows cmd.exe were launched as dummy Discord/Proton-name processes in the
workspace, then closed using real Process objects, CloseMainWindow, Stop-Process,
and exit polling. An unrelated Update.exe dummy stayed running. Process discovery
was strictly restricted to the probe images so real apps could not be selected.
This tests the native close mechanism; it does not establish the cause of a
failure on another person's installation.

Four additional portability scenarios passed in each runtime:

- A synthetic Windows user with standard Discord and two Proton version folders.
- A different synthetic user whose profile path contains spaces and brackets,
  with Discord PTB and Canary and different Proton version folders.
- Multiple Proton account files without a selection option: refused before any
  app action or write. The launchers enable the interactive selector instead.
- Include mode disabled: refused before any app action or write.

The successful profile scenarios verified default discovery from the child's
Windows environment, every current Discord executable being included, stale
paths being removed, unrelated settings/apps being preserved, an exact backup,
numeric Proton version selection, and a repeated-run no-op. Every app action
was mocked; the synthetic executable files were never executed. Live settings
and applications were not changed.

The package contains only the script, three launchers, and documentation. Its
contents were checked for personal usernames, account identifiers, and source
workspace paths. No account/settings/backup files are bundled.

The matching settings layout has been checked with Proton VPN 5.1.8. Testing
does not establish compatibility with every Proton build, actual Discord/Proton
shutdown on a friend's PC, or VPN traffic routing. Unsupported layouts are rejected.
