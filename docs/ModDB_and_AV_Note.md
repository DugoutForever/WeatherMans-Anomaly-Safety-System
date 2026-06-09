# ModDB / Antivirus Note

This project is a local backup and recovery utility for S.T.A.L.K.E.R. Anomaly/Zona/MO2 setups.

It is not a modpack and does not include third-party mods, game assets, weapon packs, textures, models, animations, or redistributed addon files.

Small unsigned tools, especially PowerShell tools compiled into EXE form, can sometimes receive antivirus false positives. The source code is included in this repository so moderators, users, and community members can inspect what the tool does.

If a moderator or user has concerns, the recommended review path is:

1. Inspect the source script in `src/`.
2. Run from source instead of EXE if desired.
3. Build the EXE locally using the included build helper.
4. Report any unsafe or unclear behavior through GitHub Issues.
