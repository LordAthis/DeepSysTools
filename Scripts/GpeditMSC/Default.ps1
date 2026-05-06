# Csoportházirend indítása vagy aktiválása
$GpPath = "$env:SystemRoot\System32\gpedit.msc"
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"

if (Test-Path $GpPath) {
    Write-Host "A Csoporthazirend elerheto. Inditas..." -ForegroundColor Green
    Start-Process "gpedit.msc"
} else {
    if ($IsHome) {
        Write-Host "A rendszered Home verzio, alapbol nincs rajta Gpedit." -ForegroundColor Yellow
        $Ans = Read-Host "Szeretned aktivalni a rendszertulajdonsagot? (I/N)"
        if ($Ans -eq "i") {
            Write-Host "Aktivalas folyamatban... Ez eltarhat egy ideig." -ForegroundColor Cyan
            # DISM alapú aktiválás a Home kiadásokhoz
            Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum" | ForEach-Object { dism /online /norestart /add-package:"$_" }
            Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" | ForEach-Object { dism /online /norestart /add-package:"$_" }
            Write-Host "Kesz! Inditas..." -ForegroundColor Green
            Start-Process "gpedit.msc"
        }
    } else {
        Write-Host "Hiba: A gpedit.msc nem talalhato!" -ForegroundColor Red
    }
}
