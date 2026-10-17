# Inspect and build Janjanator

The launcher source is `Support/Launcher.cs`. It starts the readable Windows
Forms script in `Support/Discord-Rule-Updater-GUI.ps1`. Rule management is in
`Support/Update-DiscordRules.ps1`; monitoring is in `Support/Watch-DiscordRules.ps1`.
The launcher contains no embedded updater scripts, network downloader, or installer.

From the extracted project folder, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Support\Build.ps1
```

This uses the .NET Framework C# compiler installed with Windows, embeds
`Support/Assets/App.ico`, and writes `Janjanator.exe` in the main folder.
No Visual Studio or additional packages are needed. Keep `Support` beside the EXE.
The executable is unsigned. A rebuild can have a different SHA-256 because the
compiler includes build metadata; inspect the source or decompile the assembly
to compare behavior instead of expecting identical bytes.

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
