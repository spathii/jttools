
<# 
    File: Apply-ExplorerPrefs-ByProfile.ps1
    Purpose: Apply File Explorer preferences from a CSV by profile (user/admin/jtatman/custom).
    CSV columns: profile,config_option,setting,setting_options
    Default CSV path: $PSScriptRoot\explorer_profiles.csv
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath = (Join-Path -Path $PSScriptRoot -ChildPath 'explorer_profiles.csv'),

    [Parameter(Mandatory)]
    [ValidateSet('user','admin','jtatman','custom')]
    [string]$Profile,

    [switch]$DryRun,
    [switch]$SkipBackup,
    [switch]$NoRestart
)

function Get-IsWin11 {
    $ver = (Get-CimInstance Win32_OperatingSystem).Version
    return (($ver -as [version]) -ge [version]'10.0.22000.0')
}

function New-RegBackup {
    param([string]$Hive,[string]$RegistryPath)
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $dest = Join-Path -Path $env:TEMP -ChildPath ("ExplorerPrefsBackup_{0}_{1}_{2}.reg" -f $Hive, ($RegistryPath -replace '[\\/:"]','-'), $timestamp)
        & reg.exe export "$Hive\$RegistryPath" $dest /y | Out-Null
        Write-Host "Backup: $Hive\$RegistryPath -> $dest"
    } catch {
        Write-Warning "Backup failed for $Hive\$RegistryPath: $($_.Exception.Message)"
    }
}

function Ensure-RegistryKey {
    param([string]$Hive,[string]$RegistryPath)
    $psPath = "$Hive`:\$RegistryPath"
    if (-not (Test-Path $psPath)) { New-Item -Path $psPath -Force | Out-Null }
    return $psPath
}

# Map of config_option -> registry metadata + translator (HKCU per-user)
$Map = @{
    'show_hidden' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='Hidden'; Type='DWord';
        Translate = { param($s) switch ($s.ToLower()) { 'on' {1}; 'off' {2}; default {throw "show_hidden expects on|off"}} }
    }
    'show_protected_os_files' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ShowSuperHidden'; Type='DWord';
        Translate = { param($s) switch ($s.ToLower()) { 'on' {1}; 'off' {0}; default {throw "show_protected_os_files expects on|off"}} }
    }
    'file_extensions' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='HideFileExt'; Type='DWord';
        Translate = { param($s) switch ($s.ToLower()) { 'show' {0}; 'hide' {1}; default {throw "file_extensions expects show|hide"}} }
    }
    'nav_expand_to_current' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='NavPaneExpandToCurrentFolder'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "nav_expand_to_current expects on|off" } }
    }
    'nav_show_all_folders' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='NavPaneShowAllFolders'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "nav_show_all_folders expects on|off" } }
    }
    'classic_menu_bar' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='AlwaysShowMenus'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "classic_menu_bar expects on|off" } }
    }
    'separate_explorer_process' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='SeparateProcess'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "separate_explorer_process expects on|off" } }
    }
    'titlebar_full_path' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='FullPath'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "titlebar_full_path expects on|off" } }
    }
    'quickaccess_recent' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='ShowRecent'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "quickaccess_recent expects on|off" } }
    }
    'quickaccess_frequent' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='ShowFrequent'; Type='DWord';
        Translate = { param($s) if ($s -in @('on','off')) { if ($s -eq 'on') {1} else {0} } else { throw "quickaccess_frequent expects on|off" } }
    }
    'launch_to' = @{
        Hive='HKCU'; Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='LaunchTo'; Type='DWord';
        Translate = {
            param($s)
            $is11 = Get-IsWin11
            switch ($s.ToLower()) {
                'thispc'      { if ($is11) { 2 } else { 1 } }
                'home'        { if ($is11) { 1 } else { throw "launch_to 'home' is Windows 11 only" } }
                'quickaccess' { if ($is11) { throw "launch_to 'quickaccess' is not valid on Windows 11" } else { 2 } }
                default       { throw "launch_to expects thispc|home|quickaccess" }
            }
        }
    }
}

# Resolve default CsvPath when invoked without a script context (fallback to current directory)
if (-not $CsvPath) {
    $CsvPath = Join-Path -Path (Get-Location).Path -ChildPath 'explorer_profiles.csv'
}

if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }
$all = Import-Csv -Path $CsvPath
$rows = $all | Where-Object { $_.profile -eq $Profile }

if (-not $rows -or $rows.Count -eq 0) { throw "No rows found for profile '$Profile' in $CsvPath" }

# Optional validation against 'setting_options' if present
foreach ($row in $rows) {
    $hasCol = $row.PSObject.Properties.Match('setting_options').Count -gt 0
    if ($hasCol) {
        $opts = ($row.setting_options ?? '').Trim()
        if ($opts) {
            $allowed = $opts.Split('|').ForEach({ $_.Trim().ToLower() }) | Where-Object { $_ -ne '' }
            if ($allowed.Count -gt 0 -and ($row.setting.ToLower() -notin $allowed)) {
                throw "Invalid setting for config_option='$($row.config_option)': '$($row.setting)'; allowed: '$opts'"
            }
        }
    }
}

# Backups (unique by path)
if (-not $SkipBackup) {
    $rows | ForEach-Object {
        $cfg = $Map[$_.config_option]
        if ($cfg) { New-RegBackup -Hive $cfg.Hive -RegistryPath $cfg.Path }
    } | Out-Null
}

# Apply settings
foreach ($row in $rows) {
    $option = $row.config_option
    $setting = $row.setting

    if (-not $Map.ContainsKey($option)) {
        Write-Warning "Unknown config_option '$option' — skipping."
        continue
    }

    $cfg = $Map[$option]
    $psPath = Ensure-RegistryKey -Hive $cfg.Hive -RegistryPath $cfg.Path
    $translated = & $cfg.Translate $setting
    $propType = $cfg.Type

    if ($DryRun) {
        Write-Host "[DryRun] Would set $psPath\$($cfg.Name) ($propType) = $translated"
        continue
    }

    if ($PSCmdlet.ShouldProcess("$psPath\$($cfg.Name)", "Set $propType = $translated")) {
        New-ItemProperty -Path $psPath -Name $cfg.Name -Value $translated -PropertyType $propType -Force | Out-Null
    }
}

# Restart Explorer to apply changes
if (-not $DryRun -and -not $NoRestart) {
    Write-Host "Restarting Explorer..."
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
    Write-Host "Explorer restarted."
}

Write-Host "Completed applying profile '$Profile' from: $CsvPath"
``
