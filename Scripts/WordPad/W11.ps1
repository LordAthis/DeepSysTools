# Scripts\WordPad\W11.ps1
# Ellenorzes -> Modositas/Masolas -> Futtatas

$TargetDir = "$env:ProgramFiles\Windows NT\Accessories"
$TargetFile = Join-Path $TargetDir "wordpad.exe"
$SysSource = Join-Path $PSScriptRoot "..\..\Sys\write.exe.W10.$Arch" # Relativ ut a /Sys-hez

if (Test-Path $TargetFile) {
    Write-Host "WordPad jelen van. Inditas..."
    Start-Process $TargetFile
} else {
    Write-Host "WordPad hianyzik (W11 24H2+)." -ForegroundColor Yellow
    if (Test-Path $SysSource) {
        $Ans = Read-Host "Szeretned masolni a /Sys mappabol? (I/N)"
        if ($Ans -eq "i") {
            Copy-Item $SysSource $TargetFile -Force
            Write-Host "Masolas kesz."
            Start-Process $TargetFile
        }
    } else {
        Write-Host "Hianyzik a forrasfajl: $SysSource" -ForegroundColor Red
        pause
    }
}
