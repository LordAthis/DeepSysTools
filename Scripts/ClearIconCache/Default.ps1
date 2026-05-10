# Ikon gyorsitotar uritese
# Ekezetes kommentek, ekezetmentes uzenetek

$CacheFile = "$env:LocalAppdata\IconCache.db"

if (Test-Path $CacheFile) {
    Write-Host "Intezo leallitasa a torleshez..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    
    Remove-Item $CacheFile -Force
    Write-Host "Ikon gyorsitotar torolve." -ForegroundColor Green
    
    Start-Process explorer.exe
} else {
    Write-Host "Az IconCache.db nem talalhato a standard helyen." -ForegroundColor Red
}
