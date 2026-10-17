# Inspect and build Janjanator

The launcher source is `Support/Launcher.cs`. It starts the readable Windows
Forms script in `Support/Discord-Rule-Updater-GUI.ps1`. Rule management is in
`Support/Update-DiscordRules.ps1`; monitoring is in `Support/Watch-DiscordRules.ps1`.
The launcher contains no embedded updater scripts, network downloader, or installer.

## Build your own copy with Windows' built-in .NET

If you prefer not to run a downloaded unsigned executable, download the source
from the repository's **Code → Download ZIP** menu (or clone the repository),
extract it, and review the source before building. An agent can review and build
it for you using the prompt below. The build does not need administrator access,
network access, or changes to your firewall, antivirus, or SmartScreen settings.

We recommend the **.NET Framework C# compiler included with Windows**. This is
`csc.exe`, not the modern `dotnet` SDK. No Visual Studio, NuGet packages, or SDK
installation is required when that compiler is present.

Open PowerShell in the extracted project folder (the folder containing `Support`).
To invoke the compiler directly, without a PowerShell execution-policy bypass:

```powershell
$compiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler)) {
    throw 'The Windows .NET Framework C# compiler could not be found.'
}
& $compiler /nologo /target:winexe /out:Janjanator.exe `
    /win32icon:Support\Assets\App.ico /reference:System.Windows.Forms.dll `
    Support\Launcher.cs
if ($LASTEXITCODE -ne 0) { throw 'Launcher compilation failed.' }
```

This replaces `Janjanator.exe` in that folder with your locally compiled launcher.
Keep the complete `Support` folder beside it. Building does not launch the app or
change Proton settings. If the compiler is missing, stop and report that rather
than downloading an unverified compiler or disabling security controls.

Alternatively, the existing build script performs the same compilation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Support\Build.ps1
```

This uses the .NET Framework C# compiler installed with Windows, embeds
`Support/Assets/App.ico`, and writes `Janjanator.exe` in the main folder.
No Visual Studio or additional packages are needed. Keep `Support` beside the EXE.
The command above uses `ExecutionPolicy Bypass` only for that PowerShell process;
it does not change the saved execution policy or bypass a firewall. The launcher
also uses a process-scoped execution-policy bypass to run the GUI script. Review
`Support/Launcher.cs` if that matters to your policy; compiling locally does not
remove this runtime behavior.

The executable is unsigned. A rebuild can have a different SHA-256 because the
compiler includes build metadata; inspect the source or decompile the assembly
to compare behavior instead of expecting identical bytes.
Local compilation does not add a publisher signature or guarantee that Windows
will trust the result. If Windows or your organization's policy blocks it, leave
those protections enabled and follow the applicable review process.

## Prompt for your coding agent

Copy this prompt into your agent after opening the extracted source folder:

```text
Review this Janjanator source before building it. Read Support/BUILD.md,
Support/Launcher.cs, and the PowerShell scripts the launcher and GUI invoke.
Explain any concerns you find. If there are no blocking concerns, build
Janjanator.exe using Windows' built-in .NET Framework csc.exe and the direct
compiler command in Support/BUILD.md. Do not use the downloaded executable as
the build input. Do not install an SDK or packages, disable security controls,
or change execution-policy settings. If the compiler is missing or a policy
blocks compilation, report it and stop. Check the compiler exit code and report
the output path and SHA-256 of the new executable. Do not launch the application
or change Proton settings as part of the build. Explain that it remains unsigned
and that the launcher uses a process-scoped execution-policy bypass at runtime.
```

## Offline checks

Run the offline shutdown fixtures (no real applications are stopped):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Support\tests\Shutdown-Races.Tests.ps1
```

## Sharing

Use `Support/Package.ps1` to build and package a release. Its ZIP contains only
`Janjanator.exe` and an explicit list of supporting files. Local diagnostic reports,
Proton settings, backups, Git history, and previous releases are excluded.
Upload the ZIP and its SHA-256 file to a GitHub Release. Friends should extract
the entire ZIP, then open `Janjanator.exe`.

## Automatic GitHub Releases

The workflow in `.github/workflows/release.yml` builds from tagged source on a
Windows runner, checks PowerShell syntax, runs offline fixtures, compiles the
launcher, and publishes the ZIP and SHA-256 file to a GitHub Release. It uses
GitHub's temporary repository token; do not add your personal PAT as a secret.

After pushing the workflow to the default branch, open **Actions → Build and
release Janjanator → Run workflow**. Select the branch to release and choose
**major**, **minor**, or **patch** (the default). The workflow finds the highest
existing stable `vMAJOR.MINOR.PATCH` tag, increments the selected component,
resets lower components to zero, and creates the tag at the selected commit.
For example, `v4.2.3` becomes `v5.0.0`, `v4.3.0`, or `v4.2.4`. With no stable
tags, the starting version is `0.0.0`. Prerelease and unrelated tags are ignored.

The same run then builds and publishes the release, so no personal token is
needed to trigger a second workflow. Do not create the release manually first;
the workflow creates it and attaches the compiled assets. If the build fails
after the tag is created, rerun the failed jobs to reuse that tag.

You can still create and push an unused `v` tag with Git to start a release.
Pushing only a branch does not publish anything. Existing tags do not trigger
builds retroactively. Follow progress in Actions, then download the assets from
Releases. GitHub's automatic source-code ZIP does not replace the compiled
`Janjanator.zip` asset.

If pushing the workflow with a fine-grained PAT, grant **Workflows: Read and
write** for this repository in addition to **Contents: Read and write**.
