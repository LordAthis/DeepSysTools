# DeepSysTools Launcher
$ErrorActionPreference = "Stop"

# Jogosultság emelése
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

# Rendszer adatok lekérése
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

Write-DeepLog "Rendszer indítva: $OSCaption ($OSID) [$Arch]"

if (-not (Test-Path $JsonPath)) {
    Write-DeepHost "HIBA: A SysList.json fájl nem található!" -ForegroundColor Red
    exit
}

try {
    $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8
    $Data = $RawJson | ConvertFrom-Json
} catch {
    Write-Host "Hiba a JSON feldolgozásakor! Ellenőrizd a fájl szerkezetét!" -ForegroundColor Red
    Write-DeepLog "JSON HIBA: $_"
    pause
    exit
}

Clear-Host
function Show-Menu {
    Write-Host "--- DeepSysTools ---" -ForegroundColor Yellow
    Write-Host "Rendszer: $OSCaption [$Arch]" -ForegroundColor Cyan
    Write-Host "--------------------"
    for ($i=0; $i -lt $Data.tools.Count; $i++) {
        $T = $Data.tools[$i]
        $Stat = $T.availability.$OSID.status
        if (-not $T.display_name) { continue }
        Write-Host ("[{0,2}] {1,-35} ({2})" -f ($i+1), $T.display_name, $Stat)
    }
    Write-Host "--------------------"
    Write-Host "[Q] Kilépés"
}

# Inicializáljuk a változót a [ref] számára
$Idx = 0

while ($true) {
    Show-Menu
    $Sel = Read-Host "Válassz egy számot"
    if ($Sel -eq "q") { break }
    
    if ([int]::TryParse($Sel, [ref]$Idx) -and $Idx -gt 0 -and $Idx -le $Data.tools.Count) {
        $Tool = $Data.tools[$Idx-1]
        $TID = $Tool.id
        Write-DeepLog "Indítás választva: $TID"

        # Scripts\[ID]\W10.ps1 formátum keresése
        $SpecScript = Join-Path $ScriptDir "$TID\$OSID.ps1"
        $CommonScript = Join-Path $ScriptDir "$TID\Default.ps1"

        if (Test-Path $SpecScript) {
            Write-DeepLog "Script indítása: $SpecScript"
            & $SpecScript
        }
        elseif (Test-Path $CommonScript) {
            Write-DeepLog "Script indítása: $CommonScript"
            & $CommonScript
        }
        else {
            Write-DeepLog "Direkt parancs: $($Tool.command)"
            Start-Process $Tool.command -ErrorAction SilentlyContinue
        }
    }
}
