# DeepSysTools Launcher
$ErrorActionPreference = "Stop"

# 1. Jogosultság emelése (Adminisztrátorként kell futnia a legtöbb eszközhöz)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Relatív útvonalak meghatározása a Launcher helyzetéhez képest
$RootDir = $PSScriptRoot
$LogDir  = Join-Path $RootDir "LOG"
$ScriptDir = Join-Path $RootDir "Scripts"
$JsonPath = Join-Path $RootDir "SysList.json"

# LOG mappa ellenőrzése
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$LogFile = Join-Path $LogDir "Session_$(Get-Date -Format 'yyyyMMdd').log"

function Write-DeepLog($Message) {
    $Stamp = Get-Date -Format "HH:mm:ss"
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# 3. Operációs rendszer pontos azonosítása
$OSCaption = (Get-WmiObject Win32_OperatingSystem).Caption
$OSID = ""

if ($OSCaption -like "*Windows 11*") { $OSID = "W11" }
elseif ($OSCaption -like "*Windows 10*") { $OSID = "W10" }
elseif ($OSCaption -like "*Windows 8.1*") { $OSID = "W81" }
elseif ($OSCaption -like "*Windows 8*") { $OSID = "W8" }
elseif ($OSCaption -like "*Windows 7*") { $OSID = "W7" }
elseif ($OSCaption -like "*Windows XP*") { $OSID = "XP" }
else { $OSID = "Unknown" }

Write-DeepLog "Rendszer inditva: $OSCaption ($OSID)"

# 4. SysList.json betöltése
if (-not (Test-Path $JsonPath)) {
    Write-Error "A SysList.json nem talalhato!"
    Write-DeepLog "HIBA: SysList.json hianyzik!"
    pause
    exit
}
$Data = Get-Content $JsonPath -Raw | ConvertFrom-Json

# 5. Menü és vezérlés
function Show-Menu {
    Clear-Host
    Write-Host "--- DeepSysTools ---" -ForegroundColor Yellow
    Write-Host "Rendszer: $OSCaption" -ForegroundColor Cyan
    Write-Host "--------------------"
    
    for ($i=0; $i -lt $Data.tools.Count; $i++) {
        $Tool = $Data.tools[$i]
        $Status = $Tool.availability.$OSID.status
        Write-Host ("[{0,2}] {1,-35} ({2})" -f ($i+1), $Tool.display_name, $Status)
    }
    Write-Host "--------------------"
    Write-Host "[Q] Kilepes"
}

# Fő ciklus
while ($true) {
    Show-Menu
    $Input = Read-Host "Valassz opciot"
    
    if ($Input -eq "q") { break }
    
    if ([int]::TryParse($Input, [ref]$Idx) -and $Idx -le $Data.tools.Count) {
        $SelectedTool = $Data.tools[$Idx-1]
        $ToolID = $SelectedTool.id
        $CamelName = ($ToolID -replace '_', '').Replace('msc', 'MSC').Replace('cpl', 'CPL') # Egyszerű CamelCase generálás a mappához
        
        Write-DeepLog "Kivalasztva: $($SelectedTool.display_name) ($ToolID)"
        
        # Specifikus script keresése: pl. Scripts\LusrmgrMSC\W11.ps1
        $SpecificScript = Join-Path $ScriptDir "$CamelName\$OSID.ps1"
        $CommonScript = Join-Path $ScriptDir "$CamelName\Default.ps1"
        
        if (Test-Path $SpecificScript) {
            Write-DeepLog "Specifikus script inditasa: $SpecificScript"
            & $SpecificScript
        }
        elseif (Test-Path $CommonScript) {
            Write-DeepLog "Altalanos script inditasa: $CommonScript"
            & $CommonScript
        }
        else {
            # Ha nincs külön script, direkt parancshívás (ha a státusz engedi)
            Write-DeepLog "Direkt parancs vegrehajtasa: $($SelectedTool.command)"
            try {
                Start-Process $SelectedTool.command -ErrorAction Stop
            } catch {
                Write-Host "Hiba a parancs futtatasakor: $_" -ForegroundColor Red
                Write-DeepLog "HIBA: $($SelectedTool.command) nem indithato."
                pause
            }
        }
    }
}

Write-DeepLog "DeepSysTools leállítva."
