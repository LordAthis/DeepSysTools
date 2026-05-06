# Scripts\GpeditMSC\W11.ps1

# 1. Ellenőrzés: Létezik-e a fájl a System32-ben?
$GpeditPath = "$env:SystemRoot\System32\gpedit.msc"
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"

if (Test-Path $GpeditPath) {
    Write-Host "Gpedit megtalalhato. Inditas..." -ForegroundColor Green
    Start-Process "gpedit.msc"
} else {
    if ($IsHome) {
        $Choice = Read-Host "A Gpedit hianyzik (Home verzio). Szeretne aktivalni a rendszerben? (I/N)"
        if ($Choice -eq "i") {
            Write-Host "Aktivalas folyamatban (DISM)... Ez eltarthat egy percig." -ForegroundColor Yellow
            
            # Ez a standard fix Home verziókhoz:
            dir "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum" | Add-WindowsPackage -Online
            dir "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" | Add-WindowsPackage -Online
            
            Write-Host "Modositas kesz! Inditas..." -ForegroundColor Green
            Start-Process "gpedit.msc"
        }
    } else {
        Write-Host "A fajl hianyzik, de a rendszer nem Home. Rendszerhiba allhat fenn." -ForegroundColor Red
    }
}
