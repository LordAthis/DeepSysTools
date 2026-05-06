# Helyi felhasználók kezelése
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"
# Verziózott fájl a /Sys mappában: lusrmgr.exe.W10.x64 (példa)
$SysSource = Join-Path $PSScriptRoot "..\..\Sys\lusrmgr.exe.$OSID.$Arch"
$LocalBin = Join-Path $PSScriptRoot "lusrmgr.exe"

if (-not $IsHome) {
    Write-Host "Pro/Ent rendszer. Indítás..." -ForegroundColor Green
    Start-Process "lusrmgr.msc"
} else {
    # Home verzió esetén nézzük, megvan-e már a fix
    if (Test-Path $LocalBin) {
        Write-Host "Módosított eszköz megtalálva. Indítás..." -ForegroundColor Green
        Start-Process $LocalBin
    } else {
        Write-Host "A Home verzió nem támogatja a natív lusrmgr.msc-t." -ForegroundColor Yellow
        if (Test-Path $SysSource) {
            $Ans = Read-Host "Aktiváljuk a külső segédeszközt a /Sys mappából? (I/N)"
            if ($Ans -eq "i") {
                Copy-Item $SysSource $LocalBin -Force
                Write-Host "Másolás sikeres. Indítás..." -ForegroundColor Green
                Start-Process $LocalBin
            }
        } else {
            Write-Host "Hiba: Nem található a forrás a /Sys mappában: $SysSource" -ForegroundColor Red
            pause
        }
    }
}
