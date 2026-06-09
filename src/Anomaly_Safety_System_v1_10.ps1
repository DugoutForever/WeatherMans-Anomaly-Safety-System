
# ============================================================
# ANOMALY SAFETY SYSTEM v1.10 - Working Base + New Logo
# Safe-state manager for S.T.A.L.K.E.R. Anomaly / Zona / MO2 builds
# Maintained by We4therMan
# PowerShell 5 compatible, WinForms GUI
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Version = "1.10"
$script:AppName = "Anomaly Safety System"
# Robust script directory detection. ps2exe can leave $MyInvocation.MyCommand.Path empty/null.
$script:ScriptDir = $null
try {
    if ($MyInvocation.MyCommand.Path) { $script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
} catch { }
if ([string]::IsNullOrWhiteSpace($script:ScriptDir)) {
    try { $script:ScriptDir = [System.AppDomain]::CurrentDomain.BaseDirectory } catch { }
}
if ([string]::IsNullOrWhiteSpace($script:ScriptDir)) {
    try { $script:ScriptDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { }
}
if ([string]::IsNullOrWhiteSpace($script:ScriptDir)) { $script:ScriptDir = (Get-Location).Path }
# Config handling:
# v1.6 rule: the real settings.json ONLY lives inside the USER-SELECTED Tool Storage Folder.
# The EXE/script folder must never receive Tool_Config.
# LocalAppData stores only a tiny bootstrap pointer so the tool can find the selected storage folder on next launch.
$script:BootstrapConfigDir = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Anomaly Safety System"
$script:BootstrapConfigPath = Join-Path $script:BootstrapConfigDir "bootstrap.json"
$script:Config = $null
$script:LogBox = $null

# -----------------------------
# UI THEME
# -----------------------------
$script:Bg = [System.Drawing.Color]::FromArgb(18,24,18)
$script:PanelBg = [System.Drawing.Color]::FromArgb(28,37,28)
$script:PanelBg2 = [System.Drawing.Color]::FromArgb(35,48,35)
$script:Text = [System.Drawing.Color]::FromArgb(224,238,224)
$script:Muted = [System.Drawing.Color]::FromArgb(148,172,148)
$script:Green = [System.Drawing.Color]::FromArgb(111,180,111)
$script:Border = [System.Drawing.Color]::FromArgb(111,145,111)
$script:Warn = [System.Drawing.Color]::FromArgb(188,64,56)
$script:ButtonBg = [System.Drawing.Color]::FromArgb(42,58,42)
$script:ButtonDanger = [System.Drawing.Color]::FromArgb(116,30,28)
$script:Mono = New-Object System.Drawing.Font("Consolas", 9)
$script:MonoSmall = New-Object System.Drawing.Font("Consolas", 8)
$script:TitleFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
$script:HeaderFont = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)

function New-Form {
    param([string]$Title, [int]$Width=900, [int]$Height=650)
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "$script:AppName v$script:Version - $Title"
    $f.Size = New-Object System.Drawing.Size($Width, $Height)
    $f.StartPosition = "CenterScreen"
    $f.BackColor = $script:Bg
    $f.ForeColor = $script:Text
    $f.Font = $script:Mono
    try {
        $iconCandidate = Join-Path $script:ScriptDir "Icon Asset\Anomaly_Safety_System.ico"
        if (Test-Path -LiteralPath $iconCandidate) {
            $f.Icon = New-Object System.Drawing.Icon($iconCandidate)
        } else {
            $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            if ($exePath -and (Test-Path -LiteralPath $exePath)) {
                $associatedIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
                if ($associatedIcon -ne $null) { $f.Icon = $associatedIcon }
            }
        }
    } catch { }
    return $f
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=200, [int]$H=22, [System.Drawing.Font]$Font=$null)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Location = New-Object System.Drawing.Point($X,$Y)
    $l.Size = New-Object System.Drawing.Size($W,$H)
    $l.ForeColor = $script:Text
    $l.BackColor = [System.Drawing.Color]::Transparent
    if ($Font -ne $null) { $l.Font = $Font }
    return $l
}

function New-Button {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=180, [int]$H=34, [bool]$Danger=$false)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point($X,$Y)
    $b.Size = New-Object System.Drawing.Size($W,$H)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $script:Border
    $b.ForeColor = $script:Text
    if ($Danger) { $b.BackColor = $script:ButtonDanger } else { $b.BackColor = $script:ButtonBg }
    $b.Font = $script:Mono
    return $b
}

# -----------------------------
# EMBEDDED WEATHERMAN LOGO - PUBLIC-SAFE ASSET
# -----------------------------
$script:WeatherManLogoBase64 = @'
iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAAAE8GlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4xLWMwMDIgNzkuYTZhNjM5NiwgMjAyNC8wMy8xMi0wNzo0ODoyMyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDI1LjEyIChXaW5kb3dzKSIgeG1wOkNyZWF0ZURhdGU9IjIwMjYtMDYtMDhUMjE6NTY6MDMrMDE6MDAiIHhtcDpNb2RpZnlEYXRlPSIyMDI2LTA2LTA5VDAyOjM5OjQ3KzAxOjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDI2LTA2LTA5VDAyOjM5OjQ3KzAxOjAwIiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpkZGVmNDA3MS01NTIwLTFjNDgtOTE4Ni0yMGQ2OWViMWNkNTgiIHhtcE1NOkRvY3VtZW50SUQ9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
'@

function Get-WeatherManLogoImage {
    try {
        $bytes = [Convert]::FromBase64String($script:WeatherManLogoBase64)
        $ms = New-Object System.IO.MemoryStream
        $ms.Write($bytes, 0, $bytes.Length)
        $ms.Position = 0
        $img = [System.Drawing.Image]::FromStream($ms)
        $bmp = New-Object System.Drawing.Bitmap($img)
        $img.Dispose()
        $ms.Dispose()
        return $bmp
    } catch {
        return $null
    }
}

function New-LogoPicture {
    param([int]$X, [int]$Y, [int]$Size=64)
    $pb = New-Object System.Windows.Forms.PictureBox
    $pb.Location = New-Object System.Drawing.Point($X,$Y)
    $pb.Size = New-Object System.Drawing.Size($Size,$Size)
    $pb.BackColor = [System.Drawing.Color]::Transparent
    $pb.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $img = Get-WeatherManLogoImage
    if ($img -ne $null) { $pb.Image = $img }
    return $pb
}


function New-TextBox {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=500, [int]$H=24, [bool]$Multi=$false)
    $t = New-Object System.Windows.Forms.TextBox
    $t.Text = $Text
    $t.Location = New-Object System.Drawing.Point($X,$Y)
    $t.Size = New-Object System.Drawing.Size($W,$H)
    $t.BackColor = [System.Drawing.Color]::FromArgb(12,16,12)
    $t.ForeColor = $script:Text
    $t.BorderStyle = "FixedSingle"
    $t.Font = $script:Mono
    if ($Multi) {
        $t.Multiline = $true
        $t.ScrollBars = "Vertical"
        $t.AcceptsReturn = $true
        $t.AcceptsTab = $true
    }
    return $t
}

function New-ListBox {
    param([int]$X, [int]$Y, [int]$W=300, [int]$H=300)
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Location = New-Object System.Drawing.Point($X,$Y)
    $lb.Size = New-Object System.Drawing.Size($W,$H)
    $lb.BackColor = [System.Drawing.Color]::FromArgb(12,16,12)
    $lb.ForeColor = $script:Text
    $lb.BorderStyle = "FixedSingle"
    $lb.Font = $script:Mono
    return $lb
}

function New-LogBox {
    param([int]$X=20, [int]$Y=430, [int]$W=840, [int]$H=150)
    $t = New-TextBox "" $X $Y $W $H $true
    $t.ReadOnly = $true
    return $t
}

function Log-Msg {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Message
    if ($script:LogBox -ne $null) {
        $script:LogBox.AppendText($line + [Environment]::NewLine)
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.ScrollToCaret()
    }
    Write-Host $line
}

function Sanitize-Name {
    param([string]$Name)
    $n = $Name.Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { $n = "Unnamed" }
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) { $n = $n.Replace($c, '_') }
    $n = $n -replace '[\\/:*?"<>|]', '_'
    return $n
}

function Ensure-Dir {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Get-OldLocalToolConfigPaths {
    $paths = New-Object System.Collections.Generic.List[string]
    try { $paths.Add((Join-Path $script:ScriptDir "Tool_Config")) } catch { }
    try { $paths.Add((Join-Path (Get-Location).Path "Tool_Config")) } catch { }
    try { $paths.Add((Join-Path ([Environment]::GetFolderPath("Desktop")) "Tool_Config")) } catch { }
    return @($paths | Select-Object -Unique)
}

function Remove-OldLocalToolConfigClutter {
    foreach ($p in Get-OldLocalToolConfigPaths) {
        if (![string]::IsNullOrWhiteSpace($p) -and (Test-Path $p)) {
            try {
                Remove-Item $p -Recurse -Force -ErrorAction Stop
            } catch {
                # Never block startup because of old config clutter.
            }
        }
    }
}

function Confirm-StorageFolderLooksIntentional {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

    $leaf = ""
    try { $leaf = Split-Path -Leaf ($Path.TrimEnd('\','/')) } catch { $leaf = "" }

    if ($leaf -match '^(New Folder|Ny mappe)$') {
        $msg = "Your Tool Storage Folder is named '$leaf':`r`n`r`n$Path`r`n`r`nThis often happens when Windows creates/selects a temporary new folder by accident.`r`n`r`nUse this folder anyway?"
        $r = [System.Windows.Forms.MessageBox]::Show($msg, "Confirm Tool Storage Folder", "YesNo", "Warning")
        return ($r -eq [System.Windows.Forms.DialogResult]::Yes)
    }

    return $true
}

function Start-ExplorerSafe {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        [System.Windows.Forms.MessageBox]::Show("Path is empty or not configured yet.", "Missing Path", "OK", "Warning") | Out-Null
        return
    }
    if (!(Test-Path $Path)) { Ensure-Dir $Path }
    Start-Process explorer.exe $Path | Out-Null
}

function Start-UrlSafe {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return }
    Start-Process $Url | Out-Null
}

function Browse-Folder {
    param([string]$Description="Select folder")
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Description
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
    return $null
}

function Read-JsonSafe {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    if (!(Test-Path $Path)) { return $null }
    try { return (Get-Content $Path -Raw | ConvertFrom-Json) } catch { return $null }
}

function Get-StorageSettingsPath {
    param([string]$ToolStorageRoot)
    if ([string]::IsNullOrWhiteSpace($ToolStorageRoot)) { return $null }
    return (Join-Path (Join-Path $ToolStorageRoot "Tool Config") "settings.json")
}

function Save-Config {
    param($Config)
    if ($Config -eq $null) { return }
    if ([string]::IsNullOrWhiteSpace($Config.ToolStorageRoot)) { return }

    $cfgDir = Join-Path $Config.ToolStorageRoot "Tool Config"
    Ensure-Dir $cfgDir
    $settingsPath = Join-Path $cfgDir "settings.json"

    $json = $Config | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $json -Encoding UTF8

    Ensure-Dir $script:BootstrapConfigDir
    $bootstrap = New-Object PSObject -Property @{
        ToolStorageRoot = [string]$Config.ToolStorageRoot
        SettingsPath = [string]$settingsPath
        SavedAt = [string](Get-Date)
        Version = [string]$script:Version
    }
    $bootstrap | ConvertTo-Json -Depth 5 | Set-Content -Path $script:BootstrapConfigPath -Encoding UTF8
}

function Load-Config {
    # v1.6 intentionally does NOT read Tool_Config beside the EXE or on the Desktop.
    # Only LocalAppData bootstrap -> selected Tool Storage Folder is trusted.
    $bootstrap = Read-JsonSafe $script:BootstrapConfigPath
    if ($bootstrap -eq $null) { return $null }

    $settingsPath = $null
    if ($bootstrap.SettingsPath) { $settingsPath = [string]$bootstrap.SettingsPath }
    if (![string]::IsNullOrWhiteSpace($settingsPath)) {
        $cfg = Read-JsonSafe $settingsPath
        if ($cfg -ne $null) { return $cfg }
    }

    $storageRoot = $null
    if ($bootstrap.ToolStorageRoot) { $storageRoot = [string]$bootstrap.ToolStorageRoot }
    if (![string]::IsNullOrWhiteSpace($storageRoot)) {
        $cfg = Read-JsonSafe (Get-StorageSettingsPath $storageRoot)
        if ($cfg -ne $null) { return $cfg }
    }

    return $null
}

function Validate-AnomalyRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $need = @("bin", "gamedata", "db", "appdata", "fsgame.ltx")
    foreach ($n in $need) {
        if (!(Test-Path (Join-Path $Path $n))) { return $false }
    }
    return $true
}

function Validate-MO2Root {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $need = @("mods", "profiles")
    foreach ($n in $need) {
        if (!(Test-Path (Join-Path $Path $n))) { return $false }
    }
    return $true
}

function Get-MO2Profiles {
    param([string]$MO2Root)
    $profilesPath = Join-Path $MO2Root "profiles"
    if (!(Test-Path $profilesPath)) { return @() }
    return @(Get-ChildItem $profilesPath -Directory | Sort-Object Name | ForEach-Object { $_.Name })
}

function Get-ToolPath {
    param([string]$Sub)
    return (Join-Path $script:Config.ToolStorageRoot $Sub)
}

function Ensure-StorageLayout {
    $dirs = @(
        "MEGA_SAFEPOINT_DO_NOT_MIX",
        "Major Safepoints",
        "MO2 Profile Backups",
        "Graphics Settings Backups",
        "Graphics Profiles",
        "Shader Cache Backups",
        "Savegame Backups",
        "Reports",
        "Auto Rollbacks",
        "Tool Config"
    )
    foreach ($d in $dirs) { Ensure-Dir (Get-ToolPath $d) }
}

function Copy-DirRobo {
    param([string]$Source, [string]$Dest, [string]$Label)
    if (!(Test-Path $Source)) {
        Log-Msg "SKIP missing: $Label -> $Source"
        return
    }
    Ensure-Dir $Dest
    Log-Msg "Copying $Label..."
    $args = @('"' + $Source + '"', '"' + $Dest + '"', "/MIR", "/R:1", "/W:1", "/NFL", "/NDL", "/NP") -join " "
    $p = Start-Process -FilePath "robocopy.exe" -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
    if ($p.ExitCode -le 7) {
        Log-Msg "Copied $Label"
    } else {
        Log-Msg "WARNING: robocopy exit $($p.ExitCode) while copying $Label"
    }
}

function Copy-FileSafe {
    param([string]$Source, [string]$Dest, [string]$Label)
    if (Test-Path $Source) {
        Ensure-Dir (Split-Path -Parent $Dest)
        Copy-Item $Source $Dest -Force
        Log-Msg "Copied $Label"
    } else {
        Log-Msg "SKIP missing: $Label -> $Source"
    }
}

function Write-Report {
    param([string]$Path, [string[]]$Lines)
    Ensure-Dir (Split-Path -Parent $Path)
    Set-Content -Path $Path -Value $Lines -Encoding UTF8
}

function Get-UserLtxPath { return (Join-Path $script:Config.AnomalyRoot "appdata\user.ltx") }
function Get-AxrOptionsPath { return (Join-Path $script:Config.AnomalyRoot "gamedata\configs\axr_options.ltx") }
function Get-LauncherCfgPath { return (Join-Path $script:Config.AnomalyRoot "AnomalyLauncher.cfg") }
function Get-ShaderCachePath { return (Join-Path $script:Config.AnomalyRoot "appdata\shaders_cache") }
function Get-SavegamesPath { return (Join-Path $script:Config.AnomalyRoot "appdata\savedgames") }
function Get-MO2ProfilePath { return (Join-Path (Join-Path $script:Config.MO2Root "profiles") $script:Config.ActiveMO2Profile) }
function Get-MO2OverwritePath { return (Join-Path $script:Config.MO2Root "overwrite") }

# -----------------------------
# MEGA SAFEPOINT
# -----------------------------
function Create-MegaSafepoint {
    param([bool]$Replace)
    Ensure-StorageLayout
    $mega = Get-ToolPath "MEGA_SAFEPOINT_DO_NOT_MIX"
    if ((Test-Path $mega) -and $Replace) {
        Log-Msg "Deleting existing Mega Safepoint..."
        Remove-Item $mega -Recurse -Force
    }
    Ensure-Dir $mega
    $anomOut = Join-Path $mega "Anomaly"
    $mo2Out = Join-Path $mega "MO2"
    Ensure-Dir $anomOut
    Ensure-Dir $mo2Out

    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "bin") (Join-Path $anomOut "bin") "Anomaly bin"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "db") (Join-Path $anomOut "db") "Anomaly db"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "gamedata") (Join-Path $anomOut "gamedata") "Anomaly gamedata"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "appdata") (Join-Path $anomOut "appdata") "Anomaly appdata"

    $rootFiles = @("fsgame.ltx", "AnomalyLauncher.cfg", "commandline.txt", "launcher_config.ltx")
    foreach ($rf in $rootFiles) {
        Copy-FileSafe (Join-Path $script:Config.AnomalyRoot $rf) (Join-Path $anomOut $rf) "root file $rf"
    }

    $profileSource = Get-MO2ProfilePath
    if (Test-Path $profileSource) {
        Copy-DirRobo $profileSource (Join-Path $mo2Out ("profile_" + $script:Config.ActiveMO2Profile)) "MO2 profile $($script:Config.ActiveMO2Profile)"
    }
    $overwriteSource = Get-MO2OverwritePath
    if (Test-Path $overwriteSource) {
        Copy-DirRobo $overwriteSource (Join-Path $mo2Out "overwrite") "MO2 overwrite"
    }

    $report = @()
    $report += "ANOMALY SAFETY SYSTEM - MEGA SAFEPOINT"
    $report += "Created: $(Get-Date)"
    $report += "AnomalyRoot: $($script:Config.AnomalyRoot)"
    $report += "MO2Root: $($script:Config.MO2Root)"
    $report += "ActiveMO2Profile: $($script:Config.ActiveMO2Profile)"
    $report += "ToolStorageRoot: $($script:Config.ToolStorageRoot)"
    $report += ""
    $report += "This is the isolated nuke-level recovery anchor. Other tool systems should not write into this folder."
    Write-Report (Join-Path $mega "MEGA_SAFEPOINT_REPORT.txt") $report
    Log-Msg "Mega Safepoint created."
}

function Restore-MegaSafepoint {
    $mega = Get-ToolPath "MEGA_SAFEPOINT_DO_NOT_MIX"
    if (!(Test-Path $mega)) {
        [System.Windows.Forms.MessageBox]::Show("No Mega Safepoint exists yet.", "Missing", "OK", "Warning") | Out-Null
        return
    }
    $msg = "This will restore the isolated Mega Safepoint over your current Anomaly folders and selected MO2 profile/overwrite. Continue?"
    $r = [System.Windows.Forms.MessageBox]::Show($msg, "DANGER - Restore Mega Safepoint", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $typed = [Microsoft.VisualBasic.Interaction]::InputBox("Type RESTORE to confirm Mega Safepoint restore.", "Confirm Restore", "")
    if ($typed -ne "RESTORE") { return }

    $anomIn = Join-Path $mega "Anomaly"
    $mo2In = Join-Path $mega "MO2"
    if (Test-Path (Join-Path $anomIn "bin")) { Copy-DirRobo (Join-Path $anomIn "bin") (Join-Path $script:Config.AnomalyRoot "bin") "restore bin" }
    if (Test-Path (Join-Path $anomIn "db")) { Copy-DirRobo (Join-Path $anomIn "db") (Join-Path $script:Config.AnomalyRoot "db") "restore db" }
    if (Test-Path (Join-Path $anomIn "gamedata")) { Copy-DirRobo (Join-Path $anomIn "gamedata") (Join-Path $script:Config.AnomalyRoot "gamedata") "restore gamedata" }
    if (Test-Path (Join-Path $anomIn "appdata")) { Copy-DirRobo (Join-Path $anomIn "appdata") (Join-Path $script:Config.AnomalyRoot "appdata") "restore appdata" }
    foreach ($rf in @("fsgame.ltx", "AnomalyLauncher.cfg", "commandline.txt", "launcher_config.ltx")) {
        if (Test-Path (Join-Path $anomIn $rf)) { Copy-FileSafe (Join-Path $anomIn $rf) (Join-Path $script:Config.AnomalyRoot $rf) "restore $rf" }
    }
    $profileIn = Join-Path $mo2In ("profile_" + $script:Config.ActiveMO2Profile)
    if (Test-Path $profileIn) { Copy-DirRobo $profileIn (Get-MO2ProfilePath) "restore MO2 profile" }
    if (Test-Path (Join-Path $mo2In "overwrite")) { Copy-DirRobo (Join-Path $mo2In "overwrite") (Get-MO2OverwritePath) "restore MO2 overwrite" }
    Log-Msg "Mega Safepoint restore complete."
}


# -----------------------------
# MAJOR SAFEPOINTS / FULL BACKUPS
# -----------------------------
function Create-MajorSafepoint {
    param([string]$Name)
    Ensure-StorageLayout
    $safe = Sanitize-Name $Name
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $root = Join-Path (Get-ToolPath "Major Safepoints") ($safe + "__" + $stamp)
    Ensure-Dir $root
    $anomOut = Join-Path $root "Anomaly"
    $mo2Out = Join-Path $root "MO2"
    Ensure-Dir $anomOut
    Ensure-Dir $mo2Out

    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "bin") (Join-Path $anomOut "bin") "Anomaly bin"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "db") (Join-Path $anomOut "db") "Anomaly db"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "gamedata") (Join-Path $anomOut "gamedata") "Anomaly gamedata"
    Copy-DirRobo (Join-Path $script:Config.AnomalyRoot "appdata") (Join-Path $anomOut "appdata") "Anomaly appdata"

    foreach ($rf in @("fsgame.ltx", "AnomalyLauncher.cfg", "commandline.txt", "launcher_config.ltx")) {
        Copy-FileSafe (Join-Path $script:Config.AnomalyRoot $rf) (Join-Path $anomOut $rf) "root file $rf"
    }

    $profileSource = Get-MO2ProfilePath
    if (Test-Path $profileSource) {
        Copy-DirRobo $profileSource (Join-Path $mo2Out ("profile_" + $script:Config.ActiveMO2Profile)) "MO2 profile $($script:Config.ActiveMO2Profile)"
    }
    $overwriteSource = Get-MO2OverwritePath
    if (Test-Path $overwriteSource) {
        Copy-DirRobo $overwriteSource (Join-Path $mo2Out "overwrite") "MO2 overwrite"
    }

    $report = @()
    $report += "ANOMALY SAFETY SYSTEM - MAJOR SAFEPOINT"
    $report += "Name: $safe"
    $report += "Created: $(Get-Date)"
    $report += "AnomalyRoot: $($script:Config.AnomalyRoot)"
    $report += "MO2Root: $($script:Config.MO2Root)"
    $report += "ActiveMO2Profile: $($script:Config.ActiveMO2Profile)"
    $report += "ToolStorageRoot: $($script:Config.ToolStorageRoot)"
    $report += ""
    $report += "This is a regular full backup point. Unlike the Mega Safepoint, multiple Major Safepoints can exist."
    Write-Report (Join-Path $root "MAJOR_SAFEPOINT_REPORT.txt") $report
    Log-Msg "Major Safepoint created: $safe"
}

function Get-MajorSafepoints {
    $dir = Get-ToolPath "Major Safepoints"
    Ensure-Dir $dir
    return @(Get-ChildItem $dir -Directory | Sort-Object Name -Descending | ForEach-Object { $_.Name })
}

function Restore-MajorSafepoint {
    param([string]$BackupName)
    if ([string]::IsNullOrWhiteSpace($BackupName)) { return }
    $root = Join-Path (Get-ToolPath "Major Safepoints") $BackupName
    if (!(Test-Path $root)) {
        [System.Windows.Forms.MessageBox]::Show("Major Safepoint folder not found.", "Missing", "OK", "Warning") | Out-Null
        return
    }
    $r = [System.Windows.Forms.MessageBox]::Show("Restore Major Safepoint '$BackupName' over your current Anomaly folders and selected MO2 profile/overwrite?", "Restore Major Safepoint", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $typed = [Microsoft.VisualBasic.Interaction]::InputBox("Type RESTORE to confirm Major Safepoint restore.", "Confirm Restore", "")
    if ($typed -ne "RESTORE") { return }

    $anomIn = Join-Path $root "Anomaly"
    $mo2In = Join-Path $root "MO2"
    if (Test-Path (Join-Path $anomIn "bin")) { Copy-DirRobo (Join-Path $anomIn "bin") (Join-Path $script:Config.AnomalyRoot "bin") "restore bin" }
    if (Test-Path (Join-Path $anomIn "db")) { Copy-DirRobo (Join-Path $anomIn "db") (Join-Path $script:Config.AnomalyRoot "db") "restore db" }
    if (Test-Path (Join-Path $anomIn "gamedata")) { Copy-DirRobo (Join-Path $anomIn "gamedata") (Join-Path $script:Config.AnomalyRoot "gamedata") "restore gamedata" }
    if (Test-Path (Join-Path $anomIn "appdata")) { Copy-DirRobo (Join-Path $anomIn "appdata") (Join-Path $script:Config.AnomalyRoot "appdata") "restore appdata" }
    foreach ($rf in @("fsgame.ltx", "AnomalyLauncher.cfg", "commandline.txt", "launcher_config.ltx")) {
        if (Test-Path (Join-Path $anomIn $rf)) { Copy-FileSafe (Join-Path $anomIn $rf) (Join-Path $script:Config.AnomalyRoot $rf) "restore $rf" }
    }
    $profileIn = Join-Path $mo2In ("profile_" + $script:Config.ActiveMO2Profile)
    if (Test-Path $profileIn) { Copy-DirRobo $profileIn (Get-MO2ProfilePath) "restore MO2 profile" }
    if (Test-Path (Join-Path $mo2In "overwrite")) { Copy-DirRobo (Join-Path $mo2In "overwrite") (Get-MO2OverwritePath) "restore MO2 overwrite" }
    Log-Msg "Major Safepoint restore complete: $BackupName"
}

# -----------------------------
# GRAPHICS PROFILE CAPTURE
# -----------------------------
function Is-GraphicsCommandKey {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return $false }
    $k = $Key.Trim()
    if ($k -match '^(r__|r1_|r2_|r3_|r4_|rs_|vid_|ssfx_|pfx_)') { return $true }
    if ($k -in @('renderer','texture_lod','fov','hud_fov','scope_fov','g_fov','smaa','fxaa')) { return $true }
    return $false
}

function Parse-UserLtxCommands {
    param([string]$Path)
    $items = @()
    if (!(Test-Path $Path)) { return @() }
    $lines = Get-Content $Path -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        $raw = $line
        $trim = $line.Trim()
        if ($trim.Length -eq 0) { continue }
        if ($trim.StartsWith(";") -or $trim.StartsWith("#") -or $trim.StartsWith("--")) { continue }
        $parts = $trim -split '\s+', 2
        if ($parts.Count -lt 1) { continue }
        $key = $parts[0]
        $val = ""
        if ($parts.Count -gt 1) { $val = $parts[1] }
        if (Is-GraphicsCommandKey $key) {
            $obj = New-Object PSObject -Property @{ Key=$key; Value=$val; Raw=$raw }
            $items += $obj
        }
    }
    return $items
}

function Create-GraphicsProfile {
    param([string]$Name)
    $nameSafe = Sanitize-Name $Name
    $out = Join-Path (Get-ToolPath "Graphics Profiles") $nameSafe
    if (Test-Path $out) {
        $r = [System.Windows.Forms.MessageBox]::Show("Profile exists. Overwrite it?", "Overwrite", "YesNo", "Warning")
        if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        Remove-Item $out -Recurse -Force
    }
    Ensure-Dir $out
    $user = Get-UserLtxPath
    $items = Parse-UserLtxCommands $user
    $profilePath = Join-Path $out "user_ltx_graphics_profile.json"
    $items | ConvertTo-Json -Depth 5 | Set-Content $profilePath -Encoding UTF8
    $ltxLines = @("; Anomaly Safety System graphics profile: $nameSafe", "; Captured: $(Get-Date)", "")
    foreach ($i in $items) { $ltxLines += ("{0} {1}" -f $i.Key, $i.Value).Trim() }
    Set-Content -Path (Join-Path $out "user_ltx_graphics_commands.ltx") -Value $ltxLines -Encoding UTF8
    $report = @()
    $report += "GRAPHICS PROFILE: $nameSafe"
    $report += "Captured: $(Get-Date)"
    $report += "Source: $user"
    $report += "Captured command count: $($items.Count)"
    $report += ""
    foreach ($i in $items) { $report += ("{0} = {1}" -f $i.Key, $i.Value) }
    Write-Report (Join-Path $out "PROFILE_REPORT.txt") $report
    Log-Msg "Graphics profile created: $nameSafe ($($items.Count) commands)"
}

function Apply-GraphicsProfile {
    param([string]$ProfileName)
    $profileDir = Join-Path (Get-ToolPath "Graphics Profiles") $ProfileName
    $profileJson = Join-Path $profileDir "user_ltx_graphics_profile.json"
    if (!(Test-Path $profileJson)) {
        [System.Windows.Forms.MessageBox]::Show("Profile data missing.", "Missing", "OK", "Warning") | Out-Null
        return
    }
    $r = [System.Windows.Forms.MessageBox]::Show("Apply graphics profile '$ProfileName' to user.ltx? A rollback backup will be created first.", "Apply Profile", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $user = Get-UserLtxPath
    if (!(Test-Path $user)) {
        [System.Windows.Forms.MessageBox]::Show("user.ltx was not found: $user", "Missing", "OK", "Warning") | Out-Null
        return
    }
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $rollback = Join-Path (Get-ToolPath "Auto Rollbacks") ("Before_GraphicsProfile_" + (Sanitize-Name $ProfileName) + "__" + $stamp)
    Ensure-Dir $rollback
    Copy-FileSafe $user (Join-Path $rollback "user.ltx") "rollback user.ltx"

    $profileItems = @(Get-Content $profileJson -Raw | ConvertFrom-Json)
    $map = @{}
    foreach ($it in $profileItems) { $map[$it.Key] = [string]$it.Value }

    $lines = @(Get-Content $user)
    $found = @{}
    $newLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $trim = $line.Trim()
        if ($trim.Length -eq 0 -or $trim.StartsWith(";") -or $trim.StartsWith("#") -or $trim.StartsWith("--")) {
            $newLines.Add($line)
            continue
        }
        $parts = $trim -split '\s+', 2
        $key = $parts[0]
        if ($map.ContainsKey($key)) {
            $newLines.Add(("{0} {1}" -f $key, $map[$key]).TrimEnd())
            $found[$key] = $true
        } else {
            $newLines.Add($line)
        }
    }
    $newLines.Add("")
    $newLines.Add("; ---- Anomaly Safety System injected graphics profile: $ProfileName at $stamp ----")
    foreach ($k in $map.Keys) {
        if (!$found.ContainsKey($k)) {
            $newLines.Add(("{0} {1}" -f $k, $map[$k]).TrimEnd())
        }
    }
    Set-Content -Path $user -Value $newLines -Encoding Default
    Log-Msg "Applied graphics profile: $ProfileName"
}

function Get-GraphicsProfiles {
    $dir = Get-ToolPath "Graphics Profiles"
    Ensure-Dir $dir
    return @(Get-ChildItem $dir -Directory | Sort-Object Name | ForEach-Object { $_.Name })
}

# -----------------------------
# OTHER BACKUPS
# -----------------------------
function Create-FullGraphicsBackup {
    param([string]$Name)
    $safe = Sanitize-Name $Name
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $out = Join-Path (Get-ToolPath "Graphics Settings Backups") ($safe + "__" + $stamp)
    Ensure-Dir $out
    Copy-FileSafe (Get-UserLtxPath) (Join-Path $out "user.ltx") "user.ltx"
    Copy-FileSafe (Get-AxrOptionsPath) (Join-Path $out "axr_options.ltx") "axr_options.ltx"
    Copy-FileSafe (Get-LauncherCfgPath) (Join-Path $out "AnomalyLauncher.cfg") "AnomalyLauncher.cfg"
    Write-Report (Join-Path $out "GRAPHICS_SETTINGS_BACKUP_REPORT.txt") @("Created: $(Get-Date)", "Name: $safe", "Full-file backup of user.ltx, axr_options.ltx, and launcher config.")
    Log-Msg "Full graphics settings backup created: $safe"
}


function Get-FullGraphicsBackups {
    $dir = Get-ToolPath "Graphics Settings Backups"
    Ensure-Dir $dir
    return @(Get-ChildItem $dir -Directory | Sort-Object Name | ForEach-Object { $_.Name })
}

function Restore-FullGraphicsBackup {
    param([string]$BackupName)
    if ([string]::IsNullOrWhiteSpace($BackupName)) { return }

    $backupDir = Join-Path (Get-ToolPath "Graphics Settings Backups") $BackupName
    if (!(Test-Path -LiteralPath $backupDir)) {
        [System.Windows.Forms.MessageBox]::Show("Backup folder was not found:`r`n$backupDir", "Missing", "OK", "Warning") | Out-Null
        return
    }

    $r = [System.Windows.Forms.MessageBox]::Show("Restore full graphics settings backup '$BackupName'?`r`n`r`nThis overwrites current user.ltx, axr_options.ltx, and AnomalyLauncher.cfg when those files exist in the backup.`r`n`r`nAn automatic rollback backup will be created first.", "Restore Graphics Settings", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $rollback = Join-Path (Get-ToolPath "Auto Rollbacks") ("Before_FullGraphicsRestore_" + (Sanitize-Name $BackupName) + "__" + $stamp)
    Ensure-Dir $rollback

    Copy-FileSafe (Get-UserLtxPath) (Join-Path $rollback "user.ltx") "rollback user.ltx"
    Copy-FileSafe (Get-AxrOptionsPath) (Join-Path $rollback "axr_options.ltx") "rollback axr_options.ltx"
    Copy-FileSafe (Get-LauncherCfgPath) (Join-Path $rollback "AnomalyLauncher.cfg") "rollback AnomalyLauncher.cfg"

    $srcUser = Join-Path $backupDir "user.ltx"
    $srcAxr = Join-Path $backupDir "axr_options.ltx"
    $srcLauncher = Join-Path $backupDir "AnomalyLauncher.cfg"

    if (Test-Path -LiteralPath $srcUser) { Copy-Item -LiteralPath $srcUser -Destination (Get-UserLtxPath) -Force; Log-Msg "Restored user.ltx" } else { Log-Msg "SKIP missing in backup: user.ltx" }
    if (Test-Path -LiteralPath $srcAxr) { Copy-Item -LiteralPath $srcAxr -Destination (Get-AxrOptionsPath) -Force; Log-Msg "Restored axr_options.ltx" } else { Log-Msg "SKIP missing in backup: axr_options.ltx" }
    if (Test-Path -LiteralPath $srcLauncher) { Copy-Item -LiteralPath $srcLauncher -Destination (Get-LauncherCfgPath) -Force; Log-Msg "Restored AnomalyLauncher.cfg" } else { Log-Msg "SKIP missing in backup: AnomalyLauncher.cfg" }

    Write-Report (Join-Path $rollback "ROLLBACK_REPORT.txt") @(
        "Automatic rollback created before full graphics settings restore.",
        "Created: $(Get-Date)",
        "Restored backup: $BackupName",
        "Backup path: $backupDir"
    )

    [System.Windows.Forms.MessageBox]::Show("Full graphics settings backup restored.`r`nRollback saved in Auto Rollbacks.", "Done", "OK", "Information") | Out-Null
    Log-Msg "Full graphics settings backup restored: $BackupName"
}


function Backup-ShaderCache {
    param([string]$Name)
    $src = Get-ShaderCachePath
    if (!(Test-Path $src)) { [System.Windows.Forms.MessageBox]::Show("Shader cache folder not found.", "Missing", "OK", "Warning") | Out-Null; return }
    $safe = Sanitize-Name $Name
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $out = Join-Path (Get-ToolPath "Shader Cache Backups") ($safe + "__" + $stamp)
    Copy-DirRobo $src (Join-Path $out "shaders_cache") "shader cache"
    Write-Report (Join-Path $out "SHADER_CACHE_REPORT.txt") @("Created: $(Get-Date)", "Source: $src")
}

function Restore-ShaderCache {
    param([string]$BackupName)
    $backup = Join-Path (Get-ToolPath "Shader Cache Backups") $BackupName
    $src = Join-Path $backup "shaders_cache"
    if (!(Test-Path $src)) { return }
    $r = [System.Windows.Forms.MessageBox]::Show("Restore shader cache '$BackupName' over current shader cache?", "Restore Shader Cache", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Copy-DirRobo $src (Get-ShaderCachePath) "restore shader cache"
}

function Clear-ShaderCache {
    $src = Get-ShaderCachePath
    if (!(Test-Path $src)) { Log-Msg "Shader cache missing already."; return }
    $r = [System.Windows.Forms.MessageBox]::Show("Delete current shader cache? It will regenerate on launch.", "Clear Shader Cache", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Remove-Item $src -Recurse -Force
    Log-Msg "Shader cache cleared."
}

function Get-ShaderBackups {
    $dir = Get-ToolPath "Shader Cache Backups"
    Ensure-Dir $dir
    return @(Get-ChildItem $dir -Directory | Sort-Object Name -Descending | ForEach-Object { $_.Name })
}

function Backup-Savegames {
    param([string]$Name)
    $src = Get-SavegamesPath
    if (!(Test-Path $src)) { [System.Windows.Forms.MessageBox]::Show("Savedgames folder not found.", "Missing", "OK", "Warning") | Out-Null; return }
    $safe = Sanitize-Name $Name
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $out = Join-Path (Get-ToolPath "Savegame Backups") ($safe + "__" + $stamp)
    Copy-DirRobo $src (Join-Path $out "savedgames") "savedgames"
    Write-Report (Join-Path $out "SAVEGAME_BACKUP_REPORT.txt") @("Created: $(Get-Date)", "Source: $src")
}

function Restore-Savegames {
    param([string]$BackupName)
    $backup = Join-Path (Get-ToolPath "Savegame Backups") $BackupName
    $src = Join-Path $backup "savedgames"
    if (!(Test-Path $src)) { return }
    $r = [System.Windows.Forms.MessageBox]::Show("Restore savegames '$BackupName' over current savedgames?", "Restore Saves", "YesNo", "Warning")
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Copy-DirRobo $src (Get-SavegamesPath) "restore savedgames"
}

function Get-SaveBackups {
    $dir = Get-ToolPath "Savegame Backups"
    Ensure-Dir $dir
    return @(Get-ChildItem $dir -Directory | Sort-Object Name -Descending | ForEach-Object { $_.Name })
}

function Backup-MO2Profile {
    param([string]$Name)
    $src = Get-MO2ProfilePath
    if (!(Test-Path $src)) { return }
    $safe = Sanitize-Name $Name
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $out = Join-Path (Get-ToolPath "MO2 Profile Backups") ($safe + "__" + $stamp)
    Copy-DirRobo $src (Join-Path $out $script:Config.ActiveMO2Profile) "MO2 profile backup"
    Write-Report (Join-Path $out "MO2_PROFILE_BACKUP_REPORT.txt") @("Created: $(Get-Date)", "MO2Root: $($script:Config.MO2Root)", "Profile: $($script:Config.ActiveMO2Profile)")
}

function Clone-MO2Profile {
    param([string]$NewName)
    $src = Get-MO2ProfilePath
    if (!(Test-Path $src)) { return }
    $safe = Sanitize-Name $NewName
    $dest = Join-Path (Join-Path $script:Config.MO2Root "profiles") $safe
    if (Test-Path $dest) {
        [System.Windows.Forms.MessageBox]::Show("Profile folder already exists: $safe", "Exists", "OK", "Warning") | Out-Null
        return
    }
    Copy-DirRobo $src $dest "MO2 profile clone to $safe"
    Log-Msg "MO2 profile cloned to: $safe"
}

function Create-ScanReport {
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $out = Join-Path (Get-ToolPath "Reports") ("ASS_Report__" + $stamp + ".txt")
    $lines = @()
    $lines += "ANOMALY SAFETY SYSTEM REPORT"
    $lines += "Created: $(Get-Date)"
    $lines += "Version: $script:Version"
    $lines += ""
    $lines += "PATHS"
    $lines += "AnomalyRoot: $($script:Config.AnomalyRoot)"
    $lines += "MO2Root: $($script:Config.MO2Root)"
    $lines += "ToolStorageRoot: $($script:Config.ToolStorageRoot)"
    $lines += "StorageSettingsPath: $(Get-StorageSettingsPath $script:Config.ToolStorageRoot)"
    $lines += "BootstrapConfigPath: $script:BootstrapConfigPath"
    $lines += "ActiveMO2Profile: $($script:Config.ActiveMO2Profile)"
    $lines += ""
    $checks = @(
        (Get-UserLtxPath),
        (Get-AxrOptionsPath),
        (Get-LauncherCfgPath),
        (Get-ShaderCachePath),
        (Get-SavegamesPath),
        (Get-MO2ProfilePath),
        (Get-MO2OverwritePath)
    )
    $lines += "IMPORTANT FILES / FOLDERS"
    foreach ($c in $checks) {
        if (Test-Path $c) { $lines += "FOUND`t$c" } else { $lines += "MISSING`t$c" }
    }
    $lines += ""
    $lines += "MO2 PROFILES"
    foreach ($p in Get-MO2Profiles $script:Config.MO2Root) { $lines += $p }
    $lines += ""
    $lines += "CURRENT USER.LTX GRAPHICS COMMANDS"
    $items = Parse-UserLtxCommands (Get-UserLtxPath)
    foreach ($i in $items) { $lines += ("{0} {1}" -f $i.Key, $i.Value).Trim() }
    Write-Report $out $lines
    Log-Msg "Report created: $out"
    Start-Process notepad.exe $out | Out-Null
}

# -----------------------------
# FORMS
# -----------------------------
function Show-SetupForm {
    $f = New-Form "Initial Setup" 840 520
    $f.Controls.Add((New-Label "INITIAL SETUP" 20 18 300 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Select your Anomaly folder, MO2 folder, and the storage folder where this tool keeps backups. The storage folder is where profiles/backups must load from on next launch." 20 55 780 50))

    $defaultAnom = "C:\zona\Anomaly"
    $defaultMO2 = "C:\zona\MO2"
    $defaultStore = Join-Path ([Environment]::GetFolderPath("Desktop")) "Anomaly Tools\Anomaly Saftey System\Tool Storage"
    if ($script:Config -ne $null) {
        if (![string]::IsNullOrWhiteSpace($script:Config.AnomalyRoot)) { $defaultAnom = [string]$script:Config.AnomalyRoot }
        if (![string]::IsNullOrWhiteSpace($script:Config.MO2Root)) { $defaultMO2 = [string]$script:Config.MO2Root }
        if (![string]::IsNullOrWhiteSpace($script:Config.ToolStorageRoot)) { $defaultStore = [string]$script:Config.ToolStorageRoot }
    }
    $tbAnom = New-TextBox $defaultAnom 210 105 500
    $tbMO2 = New-TextBox $defaultMO2 210 150 500
    $tbStore = New-TextBox $defaultStore 210 195 500
    $cbProfiles = New-Object System.Windows.Forms.ComboBox
    $cbProfiles.Location = New-Object System.Drawing.Point(210,240)
    $cbProfiles.Size = New-Object System.Drawing.Size(500,24)
    $cbProfiles.BackColor = [System.Drawing.Color]::FromArgb(12,16,12)
    $cbProfiles.ForeColor = $script:Text
    $cbProfiles.DropDownStyle = "DropDownList"

    $f.Controls.Add((New-Label "Anomaly Folder" 30 108 160))
    $f.Controls.Add($tbAnom)
    $bAnom = New-Button "Browse" 720 102 80
    $bAnom.Add_Click({ $p = Browse-Folder "Select Anomaly root folder"; if ($p) { $tbAnom.Text = $p } })
    $f.Controls.Add($bAnom)

    $f.Controls.Add((New-Label "MO2 Folder" 30 153 160))
    $f.Controls.Add($tbMO2)
    $bMO2 = New-Button "Browse" 720 147 80
    $bMO2.Add_Click({ $p = Browse-Folder "Select MO2 root folder"; if ($p) { $tbMO2.Text = $p } })
    $f.Controls.Add($bMO2)

    $f.Controls.Add((New-Label "Tool Storage Folder" 30 198 170))
    $f.Controls.Add($tbStore)
    $bStore = New-Button "Browse" 720 192 80
    $bStore.Add_Click({ $p = Browse-Folder "Select tool storage folder"; if ($p) { $tbStore.Text = $p } })
    $f.Controls.Add($bStore)

    $f.Controls.Add((New-Label "Active MO2 Profile" 30 243 170))
    $f.Controls.Add($cbProfiles)

    $script:LogBox = New-LogBox 20 310 780 110
    $f.Controls.Add($script:LogBox)

    $bDetect = New-Button "Load MO2 Profiles" 210 275 180
    $bDetect.Add_Click({
        $cbProfiles.Items.Clear()
        if (Validate-MO2Root $tbMO2.Text) {
            foreach ($p in Get-MO2Profiles $tbMO2.Text) { [void]$cbProfiles.Items.Add($p) }
            if ($cbProfiles.Items.Count -gt 0) { $cbProfiles.SelectedIndex = 0 }
            Log-Msg "Loaded $($cbProfiles.Items.Count) MO2 profile(s)."
        } else { Log-Msg "MO2 path is not valid." }
    })
    $f.Controls.Add($bDetect)

    $bSave = New-Button "Validate + Continue" 590 430 210 36
    $bSave.Add_Click({
        if (!(Validate-AnomalyRoot $tbAnom.Text)) { [System.Windows.Forms.MessageBox]::Show("Anomaly folder is not valid.", "Invalid", "OK", "Warning") | Out-Null; return }
        if (!(Validate-MO2Root $tbMO2.Text)) { [System.Windows.Forms.MessageBox]::Show("MO2 folder is not valid.", "Invalid", "OK", "Warning") | Out-Null; return }
        if ($cbProfiles.SelectedItem -eq $null) { [System.Windows.Forms.MessageBox]::Show("Select an MO2 profile.", "Missing", "OK", "Warning") | Out-Null; return }
        if (!(Confirm-StorageFolderLooksIntentional $tbStore.Text)) { return }
        Ensure-Dir $tbStore.Text
        $script:Config = New-Object PSObject -Property @{
            AnomalyRoot = ($tbAnom.Text -replace '[\\/]+$','')
            MO2Root = ($tbMO2.Text -replace '[\\/]+$','')
            ToolStorageRoot = ($tbStore.Text -replace '[\\/]+$','')
            ActiveMO2Profile = [string]$cbProfiles.SelectedItem
            FirstSetupComplete = $true
            MegaSafepointPromptShown = $false
        }
        Save-Config $script:Config
        Remove-OldLocalToolConfigClutter
        Ensure-StorageLayout
        Log-Msg ("Setup saved to storage folder: " + (Get-StorageSettingsPath $script:Config.ToolStorageRoot))
        $f.Close()
        Show-MegaFirstForm
    })
    $f.Controls.Add($bSave)

    $f.ShowDialog() | Out-Null
}

function Show-MegaFirstForm {
    $f = New-Form "First Mega Safepoint" 820 500
    $f.Controls.Add((New-Label "CREATE MEGA SAFEPOINT" 20 18 500 30 $script:TitleFont))
    $txt = "Before using the tool, create one full nuke-level recovery anchor. This is isolated from every other tool system. It backs up the Anomaly environment and selected MO2 profile/overwrite. If everything breaks, this is the emergency return point."
    $info = New-TextBox $txt 20 60 760 90 $true
    $info.ReadOnly = $true
    $f.Controls.Add($info)

    $f.Controls.Add((New-Label "This can be large and slow. Close Anomaly and MO2 before creating it." 20 165 760 24 $script:HeaderFont))
    $script:LogBox = New-LogBox 20 205 760 180
    $f.Controls.Add($script:LogBox)

    $bCreate = New-Button "CREATE MEGA SAFEPOINT" 20 400 260 40 $true
    $bCreate.Add_Click({
        $r = [System.Windows.Forms.MessageBox]::Show("Create the isolated Mega Safepoint now? This may take a while.", "Mega Safepoint", "YesNo", "Warning")
        if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        Create-MegaSafepoint $true
        $script:Config.MegaSafepointPromptShown = $true
        Save-Config $script:Config
        [System.Windows.Forms.MessageBox]::Show("Mega Safepoint created. You can now open the main menu.", "Done", "OK", "Information") | Out-Null
    })
    $f.Controls.Add($bCreate)

    $bSkip = New-Button "Skip For Now" 300 400 160 40
    $bSkip.Add_Click({ $script:Config.MegaSafepointPromptShown = $true; Save-Config $script:Config; $f.Close(); Show-MainMenu })
    $f.Controls.Add($bSkip)

    $bMain = New-Button "Open Main Menu" 620 400 160 40
    $bMain.Add_Click({ $f.Close(); Show-MainMenu })
    $f.Controls.Add($bMain)

    $f.ShowDialog() | Out-Null
}

function Show-MainMenu {
    $f = New-Form "Main Menu" 820 650
    $f.Controls.Add((New-Label "ANOMALY SAFETY SYSTEM" 20 18 500 30 $script:TitleFont))
    $f.Controls.Add((New-LogoPicture 715 16 62))
    $f.Controls.Add((New-Label "Current profile: $($script:Config.ActiveMO2Profile)" 20 55 675 24))
    $f.Controls.Add((New-Label "Anomaly: $($script:Config.AnomalyRoot)" 20 80 675 24))
    $f.Controls.Add((New-Label "Storage: $($script:Config.ToolStorageRoot)" 20 105 675 24))

    $mega = New-Button "MEGA SAFEPOINT / NUKE RECOVERY" 40 135 720 44
    $mega.Add_Click({ Show-MegaWindow })
    $f.Controls.Add($mega)

    $buttons = @(
        @("MAJOR SAFEPOINTS / FULL BACKUPS", { Show-MajorSafepointsWindow }),
        @("MO2 PROFILE BACKUP / CLONE", { Show-MO2Window }),
        @("GRAPHICS SETTINGS BACKUP", { Show-FullGraphicsWindow }),
        @("GRAPHICS PROFILES", { Show-GraphicsProfilesWindow }),
        @("SHADER CACHE MANAGER", { Show-ShaderWindow }),
        @("SAVEGAME BACKUP", { Show-SaveWindow }),
        @("SCAN / REPORT", { Show-ReportWindow }),
        @("SETUP / PATHS", { Show-SetupForm })
    )
    $x = 40; $y = 200; $w=340; $h=44; $gap=16
    for ($i=0; $i -lt $buttons.Count; $i++) {
        $col = $i % 2
        $row = [math]::Floor($i / 2)
        $b = New-Button $buttons[$i][0] ($x + $col*380) ($y + $row*($h+$gap)) $w $h
        $handler = $buttons[$i][1]
        $b.Add_Click($handler)
        $f.Controls.Add($b)
    }

    $openStore = New-Button "Open Tool Storage" 40 560 200 34
    $openStore.Add_Click({ Start-ExplorerSafe $script:Config.ToolStorageRoot })
    $f.Controls.Add($openStore)

    $support = New-Button "Support" 520 560 110 34
    $support.Add_Click({ Show-SupportWindow })
    $f.Controls.Add($support)

    $close = New-Button "Close" 650 560 110 34
    $close.Add_Click({ $f.Close() })
    $f.Controls.Add($close)
    $f.ShowDialog() | Out-Null
}

function Show-MegaWindow {
    $f = New-Form "Mega Safepoint" 850 560
    $f.Controls.Add((New-Label "MEGA SAFEPOINT / NUKE RECOVERY" 20 18 620 30 $script:TitleFont))
    $msg = "The Mega Safepoint is one isolated full recovery anchor stored under MEGA_SAFEPOINT_DO_NOT_MIX. Replacing it deletes the old one without making another backup. Only replace it when the current setup is working."
    $box = New-TextBox $msg 20 58 790 70 $true
    $box.ReadOnly = $true
    $f.Controls.Add($box)
    $script:LogBox = New-LogBox 20 150 790 260
    $f.Controls.Add($script:LogBox)
    $bReplace = New-Button "REPLACE MEGA SAFEPOINT" 20 430 250 40 $true
    $bReplace.Add_Click({
        $r = [System.Windows.Forms.MessageBox]::Show("Creating a new Mega Safepoint will permanently replace the existing one. Continue only if your current setup is working.", "DANGER", "YesNo", "Warning")
        if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        $typed = [Microsoft.VisualBasic.Interaction]::InputBox("Type REPLACE to overwrite the existing Mega Safepoint.", "Confirm Replace", "")
        if ($typed -ne "REPLACE") { return }
        Create-MegaSafepoint $true
    })
    $f.Controls.Add($bReplace)
    $bRestore = New-Button "RESTORE MEGA SAFEPOINT" 290 430 250 40 $true
    $bRestore.Add_Click({ Restore-MegaSafepoint })
    $f.Controls.Add($bRestore)
    $bOpen = New-Button "Open Mega Folder" 560 430 180 40
    $bOpen.Add_Click({ Start-ExplorerSafe (Get-ToolPath "MEGA_SAFEPOINT_DO_NOT_MIX") })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-MajorSafepointsWindow {
    $f = New-Form "Major Safepoints / Full Backups" 860 560
    $f.Controls.Add((New-Label "MAJOR SAFEPOINTS / FULL BACKUPS" 20 18 620 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Creates normal nameable full backups for experiments. These are separate from the isolated Mega Safepoint." 20 55 800 42))
    $lb = New-ListBox 20 115 380 300
    foreach ($p in Get-MajorSafepoints) { [void]$lb.Items.Add($p) }
    $f.Controls.Add($lb)
    $script:LogBox = New-LogBox 420 115 390 300
    $f.Controls.Add($script:LogBox)

    $bCreate = New-Button "Create Major Safepoint" 20 430 210 38
    $bCreate.Add_Click({
        $name = [Microsoft.VisualBasic.Interaction]::InputBox("Major Safepoint name:", "Create Major Safepoint", "Before Test")
        if ($name) {
            Create-MajorSafepoint $name
            $lb.Items.Clear(); foreach ($p in Get-MajorSafepoints) { [void]$lb.Items.Add($p) }
        }
    })
    $f.Controls.Add($bCreate)

    $bRestore = New-Button "Restore Selected" 245 430 170 38 $true
    $bRestore.Add_Click({ if ($lb.SelectedItem) { Restore-MajorSafepoint ([string]$lb.SelectedItem) } })
    $f.Controls.Add($bRestore)

    $bOpen = New-Button "Open Backups Folder" 430 430 200 38
    $bOpen.Add_Click({ Start-ExplorerSafe (Get-ToolPath "Major Safepoints") })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-SupportWindow {
    $f = New-Form "Support" 680 400
    $f.Controls.Add((New-Label "SUPPORT" 20 18 300 30 $script:TitleFont))
    $f.Controls.Add((New-LogoPicture 560 16 76))
    $f.Controls.Add((New-Label "WeatherMan" 20 55 300 24 $script:HeaderFont))
    $msg = "If you want to support me, subscribe to my YouTube for more tools, addons, and projects.`r`n`r`nAll I want is the motivation to create more for people interested.`r`n`r`nDiscord name: WeatherMan"
    $box = New-TextBox $msg 20 95 620 145 $true
    $box.ReadOnly = $true
    $f.Controls.Add($box)
    $yt = New-Button "Open YouTube Channel" 20 270 220 40
    $yt.Add_Click({ Start-UrlSafe "https://www.youtube.com/@weatherman9663" })
    $f.Controls.Add($yt)
    $close = New-Button "Close" 520 270 120 40
    $close.Add_Click({ $f.Close() })
    $f.Controls.Add($close)
    $f.ShowDialog() | Out-Null
}

function Show-MO2Window {
    $f = New-Form "MO2 Profile Backup / Clone" 760 460
    $f.Controls.Add((New-Label "MO2 PROFILE BACKUP / CLONE" 20 18 500 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Active profile: $($script:Config.ActiveMO2Profile)" 20 60 700 24))
    $script:LogBox = New-LogBox 20 190 700 170
    $f.Controls.Add($script:LogBox)
    $bBack = New-Button "Backup Active Profile" 20 105 220 40
    $bBack.Add_Click({ $name = [Microsoft.VisualBasic.Interaction]::InputBox("Backup name:", "MO2 Profile Backup", $script:Config.ActiveMO2Profile); if ($name) { Backup-MO2Profile $name } })
    $f.Controls.Add($bBack)
    $bClone = New-Button "Clone Active Profile" 260 105 220 40
    $bClone.Add_Click({ $name = [Microsoft.VisualBasic.Interaction]::InputBox("New MO2 profile folder name:", "Clone Profile", ($script:Config.ActiveMO2Profile + " Copy")); if ($name) { Clone-MO2Profile $name } })
    $f.Controls.Add($bClone)
    $bOpen = New-Button "Open Profiles Folder" 500 105 220 40
    $bOpen.Add_Click({ Start-ExplorerSafe (Join-Path $script:Config.MO2Root "profiles") })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-FullGraphicsWindow {
    $f = New-Form "Graphics Settings Backup" 850 560
    $f.Controls.Add((New-Label "FULL GRAPHICS SETTINGS BACKUP" 20 18 650 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Full-file backups of user.ltx, axr_options.ltx, and AnomalyLauncher.cfg. These are listed here and can be restored with rollback protection." 20 55 800 42))

    $lb = New-ListBox 20 115 360 300
    foreach ($p in Get-FullGraphicsBackups) { [void]$lb.Items.Add($p) }
    $f.Controls.Add($lb)

    $script:LogBox = New-LogBox 400 115 400 300
    $f.Controls.Add($script:LogBox)

    $bCreate = New-Button "Create Backup" 20 430 170 38
    $bCreate.Add_Click({
        $name = [Microsoft.VisualBasic.Interaction]::InputBox("Backup name:", "Graphics Settings Backup", "Working Graphics Settings")
        if ($name) {
            Create-FullGraphicsBackup $name
            $lb.Items.Clear()
            foreach ($p in Get-FullGraphicsBackups) { [void]$lb.Items.Add($p) }
        }
    })
    $f.Controls.Add($bCreate)

    $bRestore = New-Button "Restore Selected" 205 430 170 38
    $bRestore.Add_Click({
        if ($lb.SelectedItem) {
            Restore-FullGraphicsBackup ([string]$lb.SelectedItem)
        } else {
            [System.Windows.Forms.MessageBox]::Show("Select a graphics settings backup first.", "Missing", "OK", "Warning") | Out-Null
        }
    })
    $f.Controls.Add($bRestore)

    $bRefresh = New-Button "Refresh List" 390 430 150 38
    $bRefresh.Add_Click({
        $lb.Items.Clear()
        foreach ($p in Get-FullGraphicsBackups) { [void]$lb.Items.Add($p) }
        Log-Msg "Graphics settings backup list refreshed."
    })
    $f.Controls.Add($bRefresh)

    $bOpen = New-Button "Open Backup Folder" 555 430 200 38
    $bOpen.Add_Click({ Start-ExplorerSafe (Get-ToolPath "Graphics Settings Backups") })
    $f.Controls.Add($bOpen)

    $f.ShowDialog() | Out-Null
}


function Show-GraphicsProfilesWindow {
    $f = New-Form "Graphics Profiles" 850 560
    $f.Controls.Add((New-Label "GRAPHICS PROFILES" 20 18 400 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Captures broad graphics/render keys from user.ltx. Configure in-game, exit, then capture. Applying creates rollback first." 20 55 800 42))
    $lb = New-ListBox 20 115 360 300
    foreach ($p in Get-GraphicsProfiles) { [void]$lb.Items.Add($p) }
    $f.Controls.Add($lb)
    $script:LogBox = New-LogBox 400 115 400 300
    $f.Controls.Add($script:LogBox)
    $bCreate = New-Button "Capture Current" 20 430 170 38
    $bCreate.Add_Click({ $name = [Microsoft.VisualBasic.Interaction]::InputBox("Graphics profile name:", "Capture Graphics Profile", "New Graphics Profile"); if ($name) { Create-GraphicsProfile $name; $lb.Items.Clear(); foreach ($p in Get-GraphicsProfiles) { [void]$lb.Items.Add($p) } } })
    $f.Controls.Add($bCreate)
    $bApply = New-Button "Apply Selected" 205 430 170 38
    $bApply.Add_Click({ if ($lb.SelectedItem) { Apply-GraphicsProfile ([string]$lb.SelectedItem) } })
    $f.Controls.Add($bApply)
    $bOpen = New-Button "Open Profiles Folder" 390 430 190 38
    $bOpen.Add_Click({ Start-ExplorerSafe (Get-ToolPath "Graphics Profiles") })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-ShaderWindow {
    $f = New-Form "Shader Cache Manager" 820 520
    $f.Controls.Add((New-Label "SHADER CACHE MANAGER" 20 18 500 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Shader cache is normally cleared/regenerated, but backups are supported for emergency recovery." 20 55 760 30))
    $lb = New-ListBox 20 100 360 280
    foreach ($p in Get-ShaderBackups) { [void]$lb.Items.Add($p) }
    $f.Controls.Add($lb)
    $script:LogBox = New-LogBox 400 100 380 280
    $f.Controls.Add($script:LogBox)
    $bBack = New-Button "Backup Current Cache" 20 400 190 38
    $bBack.Add_Click({ $name = [Microsoft.VisualBasic.Interaction]::InputBox("Shader cache backup name:", "Shader Cache Backup", "Before Shader Test"); if ($name) { Backup-ShaderCache $name; $lb.Items.Clear(); foreach ($p in Get-ShaderBackups) { [void]$lb.Items.Add($p) } } })
    $f.Controls.Add($bBack)
    $bRest = New-Button "Restore Selected" 225 400 170 38
    $bRest.Add_Click({ if ($lb.SelectedItem) { Restore-ShaderCache ([string]$lb.SelectedItem) } })
    $f.Controls.Add($bRest)
    $bClear = New-Button "Clear Current Cache" 410 400 170 38 $true
    $bClear.Add_Click({ Clear-ShaderCache })
    $f.Controls.Add($bClear)
    $bOpen = New-Button "Open Cache Folder" 595 400 170 38
    $bOpen.Add_Click({ Start-ExplorerSafe (Join-Path $script:Config.AnomalyRoot "appdata") })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-SaveWindow {
    $f = New-Form "Savegame Backup" 780 490
    $f.Controls.Add((New-Label "SAVEGAME BACKUP" 20 18 400 30 $script:TitleFont))
    $lb = New-ListBox 20 70 360 280
    foreach ($p in Get-SaveBackups) { [void]$lb.Items.Add($p) }
    $f.Controls.Add($lb)
    $script:LogBox = New-LogBox 400 70 330 280
    $f.Controls.Add($script:LogBox)
    $bBack = New-Button "Backup Savegames" 20 370 180 38
    $bBack.Add_Click({ $name = [Microsoft.VisualBasic.Interaction]::InputBox("Save backup name:", "Savegame Backup", "Before Test"); if ($name) { Backup-Savegames $name; $lb.Items.Clear(); foreach ($p in Get-SaveBackups) { [void]$lb.Items.Add($p) } } })
    $f.Controls.Add($bBack)
    $bRest = New-Button "Restore Selected" 220 370 170 38 $true
    $bRest.Add_Click({ if ($lb.SelectedItem) { Restore-Savegames ([string]$lb.SelectedItem) } })
    $f.Controls.Add($bRest)
    $bOpen = New-Button "Open Save Folder" 410 370 170 38
    $bOpen.Add_Click({ Start-ExplorerSafe (Get-SavegamesPath) })
    $f.Controls.Add($bOpen)
    $f.ShowDialog() | Out-Null
}

function Show-ReportWindow {
    $f = New-Form "Scan / Report" 760 380
    $f.Controls.Add((New-Label "SCAN / REPORT" 20 18 400 30 $script:TitleFont))
    $f.Controls.Add((New-Label "Creates a GPT-readable report of important paths, detected files, MO2 profiles, and current user.ltx graphics commands." 20 60 700 42))
    $script:LogBox = New-LogBox 20 160 700 110
    $f.Controls.Add($script:LogBox)
    $b = New-Button "Create Report" 20 110 200 38
    $b.Add_Click({ Create-ScanReport })
    $f.Controls.Add($b)
    $open = New-Button "Open Reports Folder" 240 110 200 38
    $open.Add_Click({ Start-ExplorerSafe (Get-ToolPath "Reports") })
    $f.Controls.Add($open)
    $f.ShowDialog() | Out-Null
}

# -----------------------------
# STARTUP
# -----------------------------
Remove-OldLocalToolConfigClutter
$script:Config = Load-Config
if ($script:Config -eq $null) {
    Show-SetupForm
} else {
    if ([string]::IsNullOrWhiteSpace($script:Config.ToolStorageRoot) -or [string]::IsNullOrWhiteSpace($script:Config.AnomalyRoot) -or [string]::IsNullOrWhiteSpace($script:Config.MO2Root)) {
        Show-SetupForm
    } else {
        Ensure-StorageLayout
        Save-Config $script:Config
        if ($script:Config.MegaSafepointPromptShown -eq $false) {
            Show-MegaFirstForm
        } else {
            Show-MainMenu
        }
    }
}
