# Intezo es Start-menu ujrainditasa
# Ekezetes kommentek, ekezetmentes uzenetek

Write-Host "Intezo leallitasa..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

# Varunk egy kicsit, hogy a rendszer lezarja a folyamatokat
Start-Sleep -Seconds 2

Write-Host "Intezo ujrainditasa..." -ForegroundColor Green
Start-Process explorer.exe

# Modern UI elemek ujrainditasa (Start-menu fix)
Get-AppXPackage -AllUsers -Name Microsoft.Windows.ShellExperienceHost | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
