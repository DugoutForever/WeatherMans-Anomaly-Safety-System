$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "ANOMALY SAFETY SYSTEM v1.10 - GITHUB EXE BUILD"
Write-Host "============================================================"
Write-Host ""

$BuildDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $BuildDir
$Ps1 = Join-Path $RepoRoot "src\Anomaly_Safety_System_v1_10.ps1"
$Icon = Join-Path $RepoRoot "assets\icon\Anomaly_Safety_System.ico"
$OutDir = Join-Path $RepoRoot "dist\v1.10"
$Exe = Join-Path $OutDir "Anomaly Safety System v1.10.exe"

if (-not (Test-Path -LiteralPath $Ps1)) {
    throw "Could not find source script: $Ps1"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Source: $Ps1"
Write-Host "Icon:   $Icon"
Write-Host "Output: $Exe"
Write-Host ""

if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue)) {
    Write-Host "ps2exe was not found. Installing ps2exe for CurrentUser..."
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}

if (Test-Path -LiteralPath $Icon) {
    Invoke-ps2exe -inputFile $Ps1 -outputFile $Exe -noConsole -STA -x64 -title "Anomaly Safety System v1.10" -iconFile $Icon
} else {
    Write-Host "WARNING: Icon not found. Building without custom icon."
    Invoke-ps2exe -inputFile $Ps1 -outputFile $Exe -noConsole -STA -x64 -title "Anomaly Safety System v1.10"
}

if (Test-Path -LiteralPath $Exe) {
    Write-Host ""
    Write-Host "BUILD COMPLETE:"
    Write-Host $Exe
} else {
    throw "Build command finished, but EXE was not found."
}
