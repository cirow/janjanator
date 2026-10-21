<div align="center">
  <img src="Support/Assets/App.png" alt="Janjanator mascot" width="180">
  <h1>Janjanator</h1>
  <p>Discord updates. Your Proton VPN rules keep up.</p>
  <p><a href="https://github.com/cirow/janjanator/releases/latest">Download</a> · <a href="Support/BUILD.md">Build from source</a> · <a href="Support/README.md">Full guide</a></p>
</div>

Keep Discord in Proton VPN's **Split tunneling → Include mode** with a simple
Windows interface: preview changes, refresh rules with a backup, or let the
one-minute monitor notify you when something needs attention. Optional startup
monitoring keeps watch whenever you sign in.

1. Download **Janjanator.zip**, extract it, and open **Janjanator.exe**.
2. Enable **Include mode** in Proton VPN, then click **Refresh**.
3. Reconnect Proton before reopening Discord.

Keep the `Support` folder beside the app. Refresh closes Discord and Proton's
client, ending active calls. Monitoring only checks; you choose when to refresh.

Unofficial, unsigned, and built with readable PowerShell scripts.

## Build instructions for humans and coding agents

Start with **[Support/BUILD.md — build instructions](Support/BUILD.md)**.
Coding agents can use the **[copyable agent prompt](Support/BUILD.md#prompt-for-your-coding-agent)**
to review the source and build locally with Windows' built-in .NET Framework compiler.

Prefer to build your own copy? Download the repository's source ZIP from
**Code → Download ZIP**, extract it, and follow [Build from source](Support/BUILD.md).
We recommend the **.NET Framework C# compiler included with Windows**; no Visual
Studio, modern .NET SDK, or package downloads are needed. The guide includes a
prompt for your coding agent and a direct compiler command. You do not need to
disable your firewall, antivirus, or SmartScreen to build it. A local build is
still unsigned and may still trigger Windows security warnings.
