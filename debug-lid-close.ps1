# Debug script to trace the actual powercfg output and parsing behavior
# This will help us understand why the toggle isn't working in both directions

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "windows\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force

Write-Host "=== DEBUGGING TOGGLE-LID-CLOSE.PS1 ===" -ForegroundColor Green
Write-Host ""

# Get current power scheme
$powerScheme = (Get-ActivePowerScheme).GUID
Write-Host "Active Power Scheme: $($powerScheme)" -ForegroundColor Cyan

# GUID for lid close action setting
$lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
$powerSettingSubgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"

Write-Host "Lid Close GUID: $lidCloseGUID" -ForegroundColor Cyan
Write-Host "Power Setting Subgroup: $powerSettingSubgroup" -ForegroundColor Cyan
Write-Host ""

# Get raw powercfg query output
Write-Host "=== RAW POWERCFG OUTPUT ===" -ForegroundColor Yellow
$rawOutput = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
$rawOutput | ForEach-Object { Write-Host "RAW: $_" }

Write-Host ""
Write-Host "=== PARSING ANALYSIS ===" -ForegroundColor Yellow

# Parse current values with detailed tracing
$currentDC = $null
$currentAC = $null

Write-Host "Looking for patterns in output..." -ForegroundColor Gray

foreach ($line in $rawOutput) {
    Write-Host "Processing line: '$line'" -ForegroundColor Gray
    
    if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
        Write-Host "  ✓ Found DC match: $($matches[1])" -ForegroundColor Green
        $currentDC = Convert-HexStringToInt -HexString $matches[1]
        Write-Host "  ✓ Converted DC value: $currentDC" -ForegroundColor Green
    }
    
    if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
        Write-Host "  ✓ Found AC match: $($matches[1])" -ForegroundColor Green
        $currentAC = Convert-HexStringToInt -HexString $matches[1]
        Write-Host "  ✓ Converted AC value: $currentAC" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== CURRENT VALUES ===" -ForegroundColor Yellow
Write-Host "Current DC Value: $currentDC" -ForegroundColor White
Write-Host "Current AC Value: $currentAC" -ForegroundColor White

# Test the toggle logic
Write-Host ""
Write-Host "=== TOGGLE LOGIC TEST ===" -ForegroundColor Yellow

Write-Host "Testing toggle logic with current values..." -ForegroundColor Gray
$shouldToggleTo = if ($currentAC -eq 0) { 1 } else { 0 }
Write-Host "Based on AC=$currentAC, should toggle to: $shouldToggleTo" -ForegroundColor Cyan

# Map values to actions
$actionMap = @{
    0 = "Do nothing"
    1 = "Sleep"
    2 = "Hibernate"
    3 = "Shut down"
}

Write-Host "Current action: $($actionMap[$currentAC])" -ForegroundColor White
Write-Host "Would change to: $($actionMap[$shouldToggleTo])" -ForegroundColor White

# Test the verification logic
Write-Host ""
Write-Host "=== VERIFICATION TEST ===" -ForegroundColor Yellow

# Let's manually test the verification step
Write-Host "Testing verification with actual powercfg query..." -ForegroundColor Gray

# First, let's see what happens when we try to get the setting using our module
$powerSetting = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
if ($powerSetting) {
    Write-Host "Module Get-PowerSetting Results:" -ForegroundColor Green
    Write-Host "  AC Value: $($powerSetting.ACValue)" -ForegroundColor White
    Write-Host "  DC Value: $($powerSetting.DCValue)" -ForegroundColor White
} else {
    Write-Host "Failed to get power setting via module" -ForegroundColor Red
}

# Test the actual commands that would be executed
Write-Host ""
Write-Host "=== COMMAND EXECUTION TEST ===" -ForegroundColor Yellow

Write-Host "Commands that would be executed:" -ForegroundColor Gray
Write-Host "  powercfg /setdcvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $shouldToggleTo" -ForegroundColor White
Write-Host "  powercfg /setacvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $shouldToggleTo" -ForegroundColor White
Write-Host "  powercfg /setactive $powerScheme" -ForegroundColor White

Write-Host ""
Write-Host "=== POTENTIAL ISSUES TO CHECK ===" -ForegroundColor Red
Write-Host "1. Are the regex patterns matching correctly?" -ForegroundColor Yellow
Write-Host "2. Are the hex values being converted correctly?" -ForegroundColor Yellow
Write-Host "3. Is the power scheme GUID correct?" -ForegroundColor Yellow
Write-Host "4. Are the powercfg commands executing successfully?" -ForegroundColor Yellow
Write-Host "5. Is the verification step working correctly?" -ForegroundColor Yellow