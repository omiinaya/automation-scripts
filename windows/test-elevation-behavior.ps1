<#
.SYNOPSIS
    Test script to verify elevation behavior with success/failure scenarios.
.DESCRIPTION
    Tests the Request-Elevation function to ensure it:
    1. Only pauses on errors
    2. Automatically closes on success
    3. Properly detects success vs failure states
#>

# Import the WindowsUtils module
Import-Module .\windows\modules\WindowsUtils.psm1 -Force

function Test-SuccessScenario {
    <#
    .SYNOPSIS
        Tests a successful operation that should auto-close.
    #>
    Write-Host "`n=== Testing SUCCESS scenario ===" -ForegroundColor Green
    Write-Host "This should run elevated and auto-close on success..." -ForegroundColor Cyan
    
    # This is a harmless test that should succeed
    $testResult = Get-SystemInfo
    Write-Host "Successfully retrieved system info: $($testResult.ComputerName)" -ForegroundColor Green
    
    Write-Host "SUCCESS: This window should close automatically..." -ForegroundColor Green
    return 0
}

function Test-FailureScenario {
    <#
    .SYNOPSIS
        Tests a failure scenario that should pause for user input.
    #>
    Write-Host "`n=== Testing FAILURE scenario ===" -ForegroundColor Red
    Write-Host "This should run elevated and pause on error..." -ForegroundColor Yellow
    
    # Intentionally cause an error
    Write-Host "About to trigger an error..." -ForegroundColor Yellow
    throw "TEST ERROR: This is a deliberate error to test elevation behavior"
}

# Main execution
Write-Host "Elevation Behavior Test Script" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = Test-AdminRights
Write-Host "Running as Administrator: $isAdmin" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })

if (-not $isAdmin) {
    Request-Elevation
    exit
}

# If running as admin, test scenarios
$choice = Read-Host "`nChoose test scenario: 1=SUCCESS (auto-close), 2=FAILURE (pause on error), Q=Quit"
switch ($choice.ToUpper()) {
    "1" { Test-SuccessScenario }
    "2" { Test-FailureScenario }
    "Q" { Write-Host "Exiting..."; exit 0 }
    default { Write-Host "Invalid choice. Exiting..."; exit 1 }
}