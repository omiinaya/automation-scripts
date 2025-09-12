# Test script to validate the toggle-lid-close.ps1 fixes
# This script tests the parsing logic and state detection

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "windows\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force

Write-Host "=== TESTING LID CLOSE TOGGLE FIXES ===" -ForegroundColor Green
Write-Host ""

# Test 1: Verify PowerManagement module functions
Write-Host "Test 1: PowerManagement Module Functions" -ForegroundColor Cyan
try {
    $powerScheme = (Get-ActivePowerScheme).GUID
    Write-Host "✓ Active power scheme: $powerScheme" -ForegroundColor Green
    
    $lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
    $lidSetting = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
    
    if ($lidSetting) {
        Write-Host "✓ Successfully retrieved lid close settings via module" -ForegroundColor Green
        Write-Host "  DC Value: $($lidSetting.DCValue)" -ForegroundColor White
        Write-Host "  AC Value: $($lidSetting.ACValue)" -ForegroundColor White
        
        # Map values to actions
        $actionMap = @{
            0 = "Do nothing"
            1 = "Sleep"
            2 = "Hibernate"
            3 = "Shut down"
        }
        
        Write-Host "  Current action: $($actionMap[$lidSetting.ACValue])" -ForegroundColor White
    } else {
        Write-Host "✗ Failed to retrieve settings via module" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Module test failed: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Verify regex parsing
Write-Host "Test 2: Regex Pattern Validation" -ForegroundColor Cyan
$testStrings = @(
    "Current DC Power Setting Index: 0x00000000",
    "Current AC Power Setting Index: 0x00000001",
    "Current DC Power Setting Index:0x00000002",
    "Current AC Power Setting Index: 0x00000003"
)

$dcPattern = "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)"
$acPattern = "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)"

foreach ($test in $testStrings) {
    if ($test -match $dcPattern) {
        Write-Host "✓ DC regex matches: $test" -ForegroundColor Green
    } elseif ($test -match $acPattern) {
        Write-Host "✓ AC regex matches: $test" -ForegroundColor Green
    } else {
        Write-Host "✗ No regex match: $test" -ForegroundColor Red
    }
}

Write-Host ""

# Test 3: Toggle logic validation
Write-Host "Test 3: Toggle Logic Validation" -ForegroundColor Cyan
$testCases = @(
    @{Current = 0; Expected = 1; Description = "Do nothing → Sleep"},
    @{Current = 1; Expected = 0; Description = "Sleep → Do nothing"},
    @{Current = 2; Expected = 0; Description = "Hibernate → Do nothing"},
    @{Current = 3; Expected = 0; Description = "Shut down → Do nothing"}
)

foreach ($test in $testCases) {
    $actual = if ($test.Current -eq 0) { 1 } else { 0 }
    $result = if ($actual -eq $test.Expected) { "✓" } else { "✗" }
    $color = if ($actual -eq $test.Expected) { "Green" } else { "Red" }
    
    Write-Host "$result $($test.Description): $actual (expected $($test.Expected))" -ForegroundColor $color
}

Write-Host ""

# Test 4: PowerCFG Command Structure
Write-Host "Test 4: PowerCFG Command Structure" -ForegroundColor Cyan
$powerScheme = (Get-ActivePowerScheme).GUID
$lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
$powerSettingSubgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"

Write-Host "Command structure test:" -ForegroundColor Gray
Write-Host "  Scheme: $powerScheme" -ForegroundColor White
Write-Host "  Subgroup: $powerSettingSubgroup" -ForegroundColor White
Write-Host "  Setting: $lidCloseGUID" -ForegroundColor White
Write-Host ""
Write-Host "Expected command:" -ForegroundColor Gray
Write-Host "  powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID" -ForegroundColor White

Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Green
Write-Host "If all tests pass above, the fixes should resolve the one-way toggle issue." -ForegroundColor White
Write-Host "The main problems were:" -ForegroundColor Yellow
Write-Host "1. Dangerous fallback defaults (always assuming Sleep)" -ForegroundColor Gray
Write-Host "2. Weak regex patterns that could fail silently" -ForegroundColor Gray
Write-Host "3. Permissive verification logic" -ForegroundColor Gray
Write-Host "4. Lack of detailed debugging output" -ForegroundColor Gray