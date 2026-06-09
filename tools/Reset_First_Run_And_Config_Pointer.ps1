Write-Host "============================================================"
Write-Host "ANOMALY SAFETY SYSTEM - RESET FIRST RUN / STORAGE POINTER"
Write-Host "============================================================"
Write-Host ""
Write-Host "This removes remembered config pointers only."
Write-Host "It does NOT delete your backup/profile folders."
Write-Host ""

$local = Join-Path $env:LOCALAPPDATA "Anomaly Safety System"
$desktopToolConfig = Join-Path ([Environment]::GetFolderPath("Desktop")) "Tool_Config"
$hereToolConfig = Join-Path $PSScriptRoot "Tool_Config"

foreach ($p in @($local, $desktopToolConfig, $hereToolConfig)) {
    if (Test-Path $p) {
        Write-Host "Removing: $p"
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Not found: $p"
    }
}

Write-Host ""
Write-Host "Done. Next launch should show Initial Setup again."
Write-Host "Press ENTER to close."
Read-Host | Out-Null
