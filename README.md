# WeatherMans Anomaly Safety System

**WeatherMans Anomaly Safety System** is a backup, recovery, and profile-management utility for **S.T.A.L.K.E.R. Anomaly**, **Zona**, and **Mod Organizer 2** based Anomaly setups.

The goal of the tool is to make risky graphics tweaking, shader changes, Modded EXE testing, MO2 profile changes, and large modlist experiments safer for normal users.

## What the tool does

The tool is designed to help with:

- Creating strong safety backups / safepoints
- Backing up and restoring MO2 profiles
- Backing up graphics settings
- Capturing and applying graphics profiles
- Managing shader cache resets
- Helping recover from broken graphics/settings experiments
- Keeping backup and recovery work separated from the actual game files

## What the tool is not

This tool is **not** a modpack.

It does **not** include S.T.A.L.K.E.R. Anomaly, third-party mods, weapon packs, textures, models, game assets, or redistributed addon files.

It is a local utility made to help users protect and manage their own existing Anomaly installation.

## Why this exists

Anomaly users often experiment with Modded EXEs, shader packs, weather files, graphics settings, MO2 profiles, and large modlists. These experiments can easily break visuals, startup behavior, shader cache, or saved settings.

The philosophy behind this tool is simple:

**Let users experiment more freely by giving them better recovery tools.**

Instead of telling users not to tweak risky settings, the tool is designed to help them make backups, restore safer states, and recover faster when something breaks.

## Repository layout

```text
src/       Main PowerShell source script
assets/    Icon and logo assets
build/     Optional local EXE build helper using ps2exe
tools/     Helper BAT/PS1 files for running/resetting locally
docs/      User guide and moderator/safety notes
release/   Release packaging notes
```

## Run from source

Download the repository, then run:

```text
tools/Run_Anomaly_Safety_System_From_Source.bat
```

## Build an EXE locally

The build helper uses `ps2exe` and outputs to:

```text
dist/v1.10/Anomaly Safety System v1.10.exe
```

Run:

```text
build/Build_EXE_v1_10.bat
```

## Source and trust

The source files are included so users, moderators, and community members can inspect what the tool does.

Small unsigned PowerShell-built utilities can sometimes trigger antivirus false positives. This repository is intended to make the tool more transparent by showing the source and documentation clearly.

Official builds are maintained by **We4therMan**.

## Disclaimer

Use this tool at your own risk. Always read what a backup or restore function does before using it. The tool is designed to help protect Anomaly setups, but every modded setup is different, and users are responsible for their own files.
