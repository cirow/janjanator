# Janjanator

A Windows interface that keeps Discord executable paths current in Proton VPN's
Split tunneling Include list. Preview changes, refresh rules, or run an optional
one-minute monitor that notifies you when attention is needed.

## Download and run

Download `Janjanator.zip` from [Releases](https://github.com/cirow/janjanator/releases),
extract it completely, and open **Janjanator.exe**. Keep the **Support** folder
beside it. Windows PowerShell and the .NET Framework are used; no additional
packages are required. The executable is unsigned.

Enable Split tunneling in **Include mode** in Proton VPN before using Janjanator.
Refresh closes Discord and Proton's client, updates the rules with a backup,
and reopens Proton. Reconnect Proton before reopening Discord. Active calls end
when Discord closes.

The monitor only previews changes. Stop it through its system-tray menu. It does
not start at login or automatically refresh settings.

## Source and verification

The executable is a small launcher; the application scripts remain readable in
`Support`. See [build instructions](../Support/BUILD.md) to compile it yourself,
and [the full guide](../Support/README.md) for compatibility, troubleshooting,
and backup restoration. Release ZIPs include a SHA-256 checksum file.

This is an unofficial utility that edits Proton's internal settings format.
Unsupported formats are rejected. It does not automatically connect the VPN or
verify Discord's traffic routing.
