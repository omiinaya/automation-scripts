# Simple debug script to see powercfg output format
$activeScheme = (Get-ActivePowerScheme).GUID
$cpuSubgroupGuid = "54533251-82be-4824-96c1-47b60b740d00"
$cpuParkingGuid = "0cc5b647-c1df-4637-891a-dec35c318583"

Write-Host "Testing powercfg output format..." -ForegroundColor Yellow
Write-Host "Active Scheme GUID: $activeScheme" -ForegroundColor Cyan
Write-Host "CPU Subgroup GUID: $cpuSubgroupGuid" -ForegroundColor Cyan
Write-Host "CPU Parking GUID: $cpuParkingGuid" -ForegroundColor Cyan
Write-Host ""

$result = powercfg -q $activeScheme $cpuSubgroupGuid $cpuParkingGuid
Write-Host "Raw powercfg output:" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green
$result
Write-Host "====================" -ForegroundColor Green

Write-Host ""
Write-Host "Looking for patterns..." -ForegroundColor Yellow

# Test various patterns
$patterns = @(
    "Current AC Power Setting Index.*0x([0-9a-f]+)",
    "Current DC Power Setting Index.*0x([0-9a-f]+)", 
    "AC.*Index.*0x([0-9a-f]+)",
    "DC.*Index.*0x([0-9a-f]+)",
    "Setting Index.*0x([0-9a-f]+)",
    "0x[0-9a-f]+"
)

foreach ($pattern in $patterns) {
    $matches = $result | Select-String $pattern
    if ($matches) {
        Write-Host "Pattern '$pattern' found:" -ForegroundColor Green
        foreach ($match in $matches) {
            Write-Host "  $($match.Line.Trim())" -ForegroundColor White
        }
    } else {
        Write-Host "Pattern '$pattern' not found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press Enter to close..." -ForegroundColor Yellow
Read-Host