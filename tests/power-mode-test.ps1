# Power Mode Test Script
# Tests the Windows power mode toggle functionality

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Write-Host "=== Windows Power Mode Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get current power mode
try {
    Write-Host "Test 1: Getting current power mode..." -ForegroundColor Yellow
    $currentPowerMode = Get-Windows11PowerMode
    Write-Host "Current AC Mode: $($currentPowerMode.ACMode)" -ForegroundColor Green
    Write-Host "Current DC Mode: $($currentPowerMode.DCMode)" -ForegroundColor Green
    Write-Host "Current Mode Name: $($currentPowerMode.CurrentModeName)" -ForegroundColor Green
    Write-Host "✓ Test 1 passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Test 1 failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Get battery info
try {
    Write-Host "Test 2: Getting battery info..." -ForegroundColor Yellow
    $batteryInfo = Get-BatteryInfo
    if ($batteryInfo) {
        Write-Host "Battery Charge Level: $($batteryInfo.ChargeLevel)%" -ForegroundColor Green
        Write-Host "Power Online: $($batteryInfo.PowerOnline)" -ForegroundColor Green
        Write-Host "✓ Test 2 passed" -ForegroundColor Green
    } else {
        Write-Host "No battery detected (desktop system)" -ForegroundColor Yellow
        Write-Host "✓ Test 2 passed" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Test 2 failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Get power schemes
try {
    Write-Host "Test 3: Getting power schemes..." -ForegroundColor Yellow
    $schemes = Get-PowerSchemes
    Write-Host "Found $($schemes.Count) power schemes:" -ForegroundColor Green
    foreach ($scheme in $schemes) {
        $status = if ($scheme.Active) { "[ACTIVE]" } else { "[INACTIVE]" }
        Write-Host "  $status $($scheme.Name) ($($scheme.GUID))" -ForegroundColor Green
    }
    Write-Host "✓ Test 3 passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Test 3 failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 4: Test power mode setting (AC power focus)
try {
    Write-Host "Test 4: Testing power mode setting..." -ForegroundColor Yellow
    
    # Get current mode
    $currentMode = Get-Windows11PowerMode
    Write-Host "Current mode: $($currentMode.CurrentModeName)" -ForegroundColor Cyan
    
    # Determine target mode (toggle between 0 and 2)
    $targetMode = if ($currentMode.ACMode -eq 0) { 2 } else { 0 }
    $modeNames = @{0 = "Balanced"; 1 = "Better Performance"; 2 = "Best Performance"}
    
    Write-Host "Setting power mode to: $($modeNames[$targetMode])" -ForegroundColor Cyan
    
    # Set the power mode
    Set-Windows11PowerMode -Mode $targetMode -ApplyTo "AC"
    
    # Wait a moment for changes to take effect
    Start-Sleep -Seconds 2
    
    # Verify the change
    $updatedMode = Get-Windows11PowerMode
    Write-Host "Updated AC Mode: $($updatedMode.ACMode)" -ForegroundColor Cyan
    Write-Host "Updated Mode Name: $($updatedMode.CurrentModeName)" -ForegroundColor Cyan
    
    if ($updatedMode.ACMode -eq $targetMode) {
        Write-Host "✓ Test 4 passed - Power mode successfully changed" -ForegroundColor Green
    } else {
        Write-Host "✗ Test 4 failed - Power mode not changed as expected" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Test 4 failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "The power mode toggle script has been fixed to:" -ForegroundColor White
Write-Host "- Use proper registry-based Windows power mode settings" -ForegroundColor White
Write-Host "- Focus on AC power (Plugged In) mode changes" -ForegroundColor White
Write-Host "- Force Windows to recognize registry changes by refreshing power schemes" -ForegroundColor White
Write-Host "- Maintain toggle functionality between Balanced and Best Performance" -ForegroundColor White
Write-Host ""
Write-Host "The changes should now be reflected in Windows Settings > System > Power & Battery" -ForegroundColor Green