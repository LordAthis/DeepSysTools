# .NET Form betöltése
Add-Type -AssemblyName System.Windows.Forms

Write-Host "WMI Konzisztenzia ellenorzese..." -ForegroundColor Yellow
# Ellenőrizzük az adatbázist
$Check = winmgmt /verifyrepository
Write-Host $Check

if ($Check -like "*is INCONSISTENT*") {
    $Title = "Kritikus Rendszerhiba"
    $Msg = "A WMI adatbazis serult. Ez okozhatja a SID hibakat. Megprobaljuk javitani?"
    $Result = [System.Windows.Forms.MessageBox]::Show($Msg, $Title, "YesNo", "Warning")

    if ($Result -eq "Yes") {
        # WMI javítási folyamat
        net stop winmgmt /y
        winmgmt /salvagerepository
        net start winmgmt
        Write-Host "Javitasi kiserlet kesz." -ForegroundColor Green
    }
} else {
    Write-Host "A WMI adatbazis rendben van." -ForegroundColor Green
}
