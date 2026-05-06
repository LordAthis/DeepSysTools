# Helyi felhasználók kezelése
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"
# A /Sys mappabol valo betöltéshez a relatív út
$SysSource = Join-Path $PSScriptRoot "..\..\Sys\lusrmgr.exe.$OSID.$Arch"
$LocalBin = Join-Path $PSScriptRoot "lusrmgr.exe"

if (-not $IsHome) {
    Write-Host "Pro/Ent rendszer. Inditas..." -ForegroundColor Green
    Start-Process "lusrmgr.msc"
} else {
    if (Test-Path $LocalBin) {
        Write-Host "Modositott eszkoz megtalalva. Inditas..." -ForegroundColor Green
        Start-Process $LocalBin
    } else {
        Write-Host "A Home verzio nem tamogatja a nativ lusrmgr.msc-t." -ForegroundColor Yellow
        if (Test-Path $SysSource) {
            $Ans = Read-Host "Aktivaljuk a kulso segedeszkozt a /Sys mappabol? (I/N)"
            if ($Ans -eq "i") {
                Copy-Item $SysSource $LocalBin -Force
                Write-Host "Masolas sikeres. Inditas..." -ForegroundColor Green
                Start-Process $LocalBin
            }
        } else {
            Write-Host "Hiba: Nem talalhato a forras a /Sys mappaban: $SysSource" -ForegroundColor Red
        }
    }
}
