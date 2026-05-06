# Csoportházirend indítása vagy aktiválása
$GpPath = "$env:SystemRoot\System32\gpedit.msc"
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"

# 1. Lekérdezzük, hogy létezik-e már
if (Test-Path $GpPath) {
    Write-Host "A Csoportházirend elérhető. Indítás..." -ForegroundColor Green
    Start-Process "gpedit.msc"
} else {
    if ($IsHome) {
        Write-Host "A rendszered Home verzió, alapból nincs rajta Gpedit." -ForegroundColor Yellow
        $Ans = Read-Host "Szeretnéd aktiválni a rendszertulajdonságot? (I/N)"
        if ($Ans -eq "i") {
            Write-Host "Aktiválás folyamatban... Ez eltarhat egy ideig." -ForegroundColor Cyan
            # DISM alapú engedélyezés
            Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum" | ForEach-Object { dism /online /norestart /add-package:"$_" }
            Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" | ForEach-Object { dism /online /norestart /add-package:"$_" }
            
            Write-Host "Kész! Indítás..." -ForegroundColor Green
            Start-Process "gpedit.msc"
        }
    } else {
        Write-Host "Hiba: A gpedit.msc nem található, pedig a rendszer nem Home!" -ForegroundColor Red
        pause
    }
}
