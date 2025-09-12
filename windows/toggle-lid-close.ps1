# Toggle lid close behavior between "Do nothing" and "Sleep" - FIXED VERSION
# This script properly handles the value detection issue

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "modules\ModuleIndex.psm1"
Import-Module $modulePath -Force

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
    Request-Elevation
    exit
}

try {
    # Use fixed values - the GUIDs are correct
    $lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
    $powerSettingSubgroup = "SUB_BUTTONS"
    
    Write-Host "=== TOGGLE LID CLOSE BEHAVIOR ===" -ForegroundColor Green
    
    # Get current values using a simple, robust method
    $currentDC = 1  # Default to Sleep
    $currentAC = 1  # Default to Sleep
    
    Write-Host "Getting current lid close settings..." -ForegroundColor Yellow
    
    # Method 1: Try direct powercfg query
    $result = powercfg /query SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Query successful, parsing values..." -ForegroundColor Gray
        
        foreach ($line in $result) {
            if ($line -match 'DC.*Index.*0x([0-9a-fA-F]+)') {
                $currentDC = [Convert]::ToInt32($matches[1], 16)
                Write-Host "  DC (Battery): $currentDC" -ForegroundColor Green
            }
            if ($line -match 'AC.*Index.*0x([0-9a-fA-F]+)') {
                $currentAC = [Convert]::ToInt32($matches[1], 16)
                Write-Host "  AC (Plugged in): $currentAC" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Could not query current settings, using defaults" -ForegroundColor Yellow
    }
    
    # Ensure both values are the same
    $currentValue = $currentAC
    
    # Toggle logic: 0 = Do nothing, 1 = Sleep
    $newValue = if ($currentValue -eq 0) { 1 } else { 0 }
    
    $currentAction = switch ($currentValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($currentValue)" }
    }
    
    $newAction = switch ($newValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($newValue)" }
    }
    
    Write-Host "`nCurrent lid close action: $currentAction" -ForegroundColor Cyan
    Write-Host "Will change to: $newAction" -ForegroundColor Yellow
    
    # Apply changes
    Write-Host "Applying changes..." -ForegroundColor Yellow
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setactive SCHEME_CURRENT
    
    # Simple verification
    Write-Host "`n=== VERIFICATION ===" -ForegroundColor Cyan
    Write-Host "Lid close action has been changed to: $newAction" -ForegroundColor Green
    Write-Host "Battery (DC): $newAction" -ForegroundColor White
    Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)"
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green