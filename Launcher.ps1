# DeepSysTools Launcher
$ErrorActionPreference = "Stop"

# Jogosultság emelése
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Utvonalak beallitasa
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

# Rendszer adatok lekérése
$OSCaption = (Get-WmiObject Win32_OperatingSystem).Caption
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$OSID = if ($OSCaption -like "*Windows 11*") { "W11" } elseif ($OSCaption -like "*10*") { "W10" } else { "Legacy" }

Write-DeepLog "Inditas: $OSCaption ($OSID)"

# Hatterfolyamat inditasa (.NET Runspace)
try {
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.Open()
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace = $Runspace
    $PowerShell.AddScript({
        param($SPath, $RDir)
        & $SPath -RootDir $RDir
    }).AddParameter("SPath", (Join-Path $ScriptDir "Searching.ps1")).AddParameter("RDir", $RootDir) | Out-Null
    $AsyncResult = $PowerShell.BeginInvoke()
    Write-DeepLog "Searching.ps1 elinditva a hatterben."
} catch { Write-DeepLog "Hatterfolyamat hiba: $_" }

# JSON betöltése
if (-not (Test-Path $JsonPath)) { Write-Host "Hianyzik a SysList.json!" -ForegroundColor Red; exit }
$Data = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Categories = $Data.tools.category | Select-Object -Unique | Where-Object { $_ -ne $null }

# Globalis valtozok inicializalasa
$GlobalQuit = $false

# FO CIKLUS (Kategoriak)
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
        
        # ALMENÜ CIKLUS (Eszközök)
        while ($true) {    
            Clear-Host
            Write-Host "--- Kategoria: $SelCat ---" -ForegroundColor Cyan
            $Filtered = $Data.tools | Where-Object { $_.category -eq $SelCat }
            $List = New-Object System.Collections.Generic.List[Object]
            
            $count = 1
            foreach ($T in $Filtered) {
                if (-not $T.display_name) { continue }
                Write-Host ("[{0,2}] {1}" -f $count, $T.display_name)
                $List.Add($T)
                $count++
            }
            Write-Host "--------------------"
            Write-Host "[B] Vissza a kategoriakhoz"
            Write-Host "[Q] Kilepes a programbol"

            $ToolInput = Read-Host "Valassz"

            if ($ToolInput -eq "q") { $GlobalQuit = $true; break }
            if ($ToolInput -eq "b") { break }

            $tIdx = 0
            if ([int]::TryParse($ToolInput, [ref]$tIdx) -and $tIdx -gt 0 -and $tIdx -le $List.Count) {
                $Tool = $List[$tIdx-1]
                $TID = $Tool.id 
                Write-DeepLog "Inditas: $TID"

                $Spec = Join-Path $ScriptDir "$TID\$OSID.ps1"
                $Def = Join-Path $ScriptDir "$TID\Default.ps1"

                if (Test-Path $Spec) { & $Spec }
                elseif (Test-Path $Def) { & $Def }
                else {
                    # CMD Bypass inditas (Barmit megnyit, ami parancssorbol megy)
                    $CmdArgs = "/c start `"`" `"$($Tool.command)`""
                    try {
                        Start-Process cmd.exe -ArgumentList $CmdArgs -WindowStyle Hidden
                    } catch { Write-DeepLog "HIBA: $($Tool.command) nem indithato." }
                }
                Write-Host "`nNyomj Entert a folytatashoz..."
                $null = Read-Host
            }
        }
        if ($GlobalQuit) { break }
    }
}
Write-DeepLog "Program leallitava."
