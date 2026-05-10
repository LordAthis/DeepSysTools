# DeepSysTools Launcher - Kategoria alapú
$ErrorActionPreference = "Stop"

# Jogosultság emelése
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$RootDir = $PSScriptRoot
$LogDir  = Join-Path $RootDir "LOG"
$ScriptDir = Join-Path $RootDir "Scripts"
$JsonPath = Join-Path $RootDir "SysList.json"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "Session_$(Get-Date -Format 'yyyyMMdd').log"

function Write-DeepLog($Msg) {
    $Stamp = Get-Date -Format "HH:mm:ss"
    "[$Stamp] $Msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Rendszer info
$OSCaption = (Get-WmiObject Win32_OperatingSystem).Caption
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$OSID = if ($OSCaption -like "*Windows 11*") { "W11" } elseif ($OSCaption -like "*10*") { "W10" } else { "Legacy" }

Write-DeepLog "Inditas: $OSCaption ($OSID)"

# .NET alapú háttérfolyamat (Runspace) létrehozása
$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()

$PowerShell = [powershell]::Create()
$PowerShell.Runspace = $Runspace

# Átadjuk a szükséges útvonalakat a háttérszálnak
$PowerShell.AddScript({
    param($SPath, $RDir)
    & $SPath -RootDir $RDir
}).AddParameter("SPath", (Join-Path $ScriptDir "Searching.ps1")).AddParameter("RDir", $RootDir) | Out-Null

# Indítás aszinkron módon
$AsyncResult = $PowerShell.BeginInvoke()
Write-DeepLog "Searching.ps1 elinditva a hatterben (.NET Runspace)"


# JSON betöltés
$Data = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Categories = $Data.tools.category | Select-Object -Unique | Where-Object { $_ -ne $null }

# A változó értékének inicializálása
$GlobalQuit = $false

while ($true) {
    Clear-Host
    Write-Host "--- DeepSysTools - Kategoriak ---" -ForegroundColor Yellow
    Write-Host "Rendszer: $OSCaption [$Arch]" -ForegroundColor Cyan
    Write-Host "--------------------"
    for ($i=0; $i -lt $Categories.Count; $i++) {
        Write-Host ("[{0,2}] {1}" -f ($i+1), $Categories[$i])
    }
    Write-Host "--------------------"
    Write-Host "[Q] Kilepes"

    $CatInput = Read-Host "Valassz kategoriat"
    if ($CatInput -eq "q") { break }

    $cIdx = 0
    if ([int]::TryParse($CatInput, [ref]$cIdx) -and $cIdx -gt 0 -and $cIdx -le $Categories.Count) {
        $SelCat = $Categories[$cIdx-1]
        
        while ($true) {
            Clear-Host
            Write-Host "--- Kategoria: $SelCat ---" -ForegroundColor Cyan
            $Filtered = $Data.tools | Where-Object { $_.category -eq $SelCat }
            $List = New-Object System.Collections.Generic.List[Object]
            
            $count = 1
            foreach ($T in $Filtered) {
                Write-Host ("[{0,2}] {1}" -f $count, $T.display_name)
                $List.Add($T)
                $count++
            }
            Write-Host "--------------------"
            Write-Host "[B] Vissza"
            Write-Host "[Q] Kilepes"

            $ToolInput = Read-Host "Valassz eszkozt"
            if ($ToolInput -eq "b") { break }

            $tIdx = 0
                        if ([int]::TryParse($ToolInput, [ref]$tIdx) -and $tIdx -gt 0 -and $tIdx -le $List.Count) {
                $Tool = $List[$tIdx-1]
                $TID = $Tool.id
                Write-DeepLog "Futtatas: $TID"

                # Útvonalak keresése a JSON ID-ja alapján
                $Spec = Join-Path $ScriptDir "$TID\$OSID.ps1"
                $Def = Join-Path $ScriptDir "$TID\Default.ps1"

                if (Test-Path $Spec) { 
                    & $Spec 
                }
                elseif (Test-Path $Def) { 
                    & $Def 
                }
                else {
                    # Ha nincs külön script, direkt parancs inditása
                    Write-DeepLog "Direkt parancs inditasa: $($Tool.command)"
                    
                    # Speciális shell hivatkozások kezelése explorerrel
                    if ($Tool.command -like "shell:*" -or $Tool.command -like "*:::{*") {
                        Start-Process explorer.exe -ArgumentList $Tool.command
                    }
                    else {
                        # Normal inditás, hiba esetén (SID/Process hiba) fallback az Explorerre
                        try {
                            Start-Process $Tool.command -ErrorAction Stop
                        } catch {
                            Write-DeepLog "SID/Process hiba, ujraprobalas Explorerrel..."
                            Start-Process explorer.exe -ArgumentList $Tool.command
                        }
                    }
                }
                Write-Host "`nNyomj Entert a folytatashoz..."
                $null = Read-Host
            }
        }
    }
}
