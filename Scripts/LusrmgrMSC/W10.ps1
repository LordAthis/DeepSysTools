# Scripts\LusrmgrMSC\W11.ps1
$ToolPath = Join-Path $PSScriptRoot "lusrmgr.exe" # A fixált verzió helye

# 1. Ellenőrzés: Pro/Enterprise vagy Home?
$IsHome = (Get-WmiObject Win32_OperatingSystem).Caption -like "*Home*"

if (-not $IsHome) {
    # Pro/Ent verzió: Alapból működik
    Write-Host "Rendszer tamogatva (Pro/Ent). Inditas..." -ForegroundColor Green
    Start-Process "lusrmgr.msc"
} else {
    # Home verzió: Kell a módosítás/külső tool
    if (Test-Path $ToolPath) {
        Write-Host "A modositas (kulso eszkoz) mar jelen van. Futtatas..." -ForegroundColor Cyan
        Start-Process $ToolPath
    } else {
        $Choice = Read-Host "A Home verzio alapbol nem tamogatja ezt. Telepitjuk a javitast? (I/N)"
        if ($Choice -eq "i") {
            Write-Host "Javitas letoltese/masolasa..." -ForegroundColor Yellow
            # Itt történne a letöltés vagy a fájl aktiválása
            Write-Host "Helyezze a 'lusrmgr.exe'-t a mappa melle!" -ForegroundColor Red
        } else {
            Write-Host "Futtatas megkiserlese modositas nelkul..."
            Start-Process "lusrmgr.msc"
        }
    }
}
