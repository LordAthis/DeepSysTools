# DeepSysTools Launcher
$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$RootDir = $PSScriptRoot
$LogDir  = Join-Path $RootDir "LOG"
$ScriptDir = Join-Path $RootDir "Scripts"
$SysDir = Join-Path $RootDir "Sys"
$JsonPath = Join-Path $RootDir "SysList.json"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
if (-not (Test-Path $SysDir)) { New-Item -ItemType Directory -Path $SysDir | Out-Null }

$LogFile = Join-Path $LogDir "Session_$(Get-Date -Format 'yyyyMMdd').log"

function Write-DeepLog($Message) {
    $Stamp = Get-Date -Format "HH:mm:ss"
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# OS es Architektura detektalas
$OSCaption = (Get-WmiObject Win32_OperatingSystem).Caption
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$OSID = ""

if ($OSCaption -like "*Windows 11*") { $OSID = "W11" }
elseif ($OSCaption -like "*Windows 10*") { $OSID = "W10" }
elseif ($OSCaption -like "*Windows 8.1*") { $OSID = "W81" }
elseif ($OSCaption -like "*Windows 8*") { $OSID = "W8" }
elseif ($OSCaption -like "*Windows 7*") { $OSID = "W7" }
elseif ($OSCaption -like "*Windows XP*") { $OSID = "XP" }
else { $OSID = "Unknown" }

Write-DeepLog "Inditas: $OSCaption ($OSID) $Arch"

if (-not (Test-Path $JsonPath)) {
    Write-DeepLog "HIBA: SysList.json hianyzik!"
    exit
}

# JSON betoltes hibakezelessel
try {
    $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8
    $Data = $RawJson | ConvertFrom-Json
} catch {
    Write-Host "JSON hiba! Ellenorizd a SysList.json tartalmat!" -ForegroundColor Red
    Write-DeepLog "HIBA: JSON parszolas sikertelen: $_"
    pause
    exit
}

function Show-Menu {
    Clear-Host
    Write-Host "--- DeepSysTools ---"
    Write-Host "OS: $OSCaption [$Arch]"
    Write-Host "--------------------"
    for ($i=0; $i -lt $Data.tools.Count; $i++) {
        $T = $Data.tools[$i]
        $Stat = $T.availability.$OSID.status
        Write-Host ("[{0,2}] {1,-35} ({2})" -f ($i+1), $T.display_name, $Stat)
    }
    Write-Host "--------------------"
    Write-Host "[Q] Kilepes"
}

while ($true) {
    Show-Menu
    $Sel = Read-Host "Valassz"
    if ($Sel -eq "q") { break }
    if ([int]::TryParse($Sel, [ref]$Idx) -and $Idx -le $Data.tools.Count) {
        $Tool = $Data.tools[$Idx-1]
        $TID = $Tool.id
        Write-DeepLog "Kivalasztva: $TID"

        $SpecScript = Join-Path $ScriptDir "$TID\$OSID.ps1"
        $CommonScript = Join-Path $ScriptDir "$TID\Default.ps1"

        if (Test-Path $SpecScript) { & $SpecScript }
        elseif (Test-Path $CommonScript) { & $CommonScript }
        else {
            Start-Process $Tool.command -ErrorAction SilentlyContinue
        }
    }
}
