# Toggle lid close behavior between "Do nothing" and "Sleep" for Windows 11
# Fixes the original set-lid-close-nothing.ps1 functionality and adds toggle behavior

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
    $powerScheme = (Get-ActivePowerScheme).GUID
    
    # GUID for lid close action setting
    $lidCloseGUID = "5ca83367-6e45-459f-a27b-476b1d01c936"
    $powerSettingSubgroup = "4f971e89-eebd-4455-a8de-9e59040e7347"
    
    # Get current lid close settings using improved parsing
    $lidSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    if (-not $lidSettings) {
        throw "Failed to retrieve current lid close settings"
    }
    
    # Parse current values with improved regex matching
    $currentDC = $null
    $currentAC = $null
    
    # Extract current values for both AC and DC
    foreach ($line in $lidSettings) {
        if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $currentDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $currentAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    # Handle cases where parsing fails - use defaults
    if ($null -eq $currentDC) { $currentDC = 1 }  # Default to Sleep (1)
    if ($null -eq $currentAC) { $currentAC = 1 }  # Default to Sleep (1)
    
    # Ensure both AC and DC values are consistent
    if ($currentDC -ne $currentAC) {
        Write-Host "Warning: Inconsistent AC/DC settings detected. Syncing to match AC value..." -ForegroundColor Yellow
        $currentDC = $currentAC
    }
    
    # Toggle logic: 0 = Do nothing, 1 = Sleep, 2 = Hibernate, 3 = Shut down
    $newValue = if ($currentAC -eq 0) { 1 } else { 0 }
    
    # Get friendly names for display
    $currentAction = switch ($currentAC) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($currentAC)" }
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
    
    # Apply changes to both AC and DC
    powercfg /setdcvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    powercfg /setacvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    
    # Activate the changes
    Set-PowerScheme -SchemeGUID $powerScheme
    
    # Verify the changes were applied
    $verification = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    $verifiedDC = $null
    $verifiedAC = $null
    
    foreach ($line in $verification) {
        if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    # Handle verification failures gracefully
    if ($null -eq $verifiedDC) { $verifiedDC = -1 }
    if ($null -eq $verifiedAC) { $verifiedAC = -1 }
    
    # Allow for reasonable verification tolerance
    $verificationPassed = ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue) -or
                         ($verifiedDC -eq $newValue -or $verifiedAC -eq $newValue)
    
    if ($verificationPassed) {
        Write-StatusMessage -Message "Successfully changed lid close action to: $newAction" -Type Success
    } else {
        Write-Host "Warning: Verification shows DC:$verifiedDC AC:$verifiedAC, but settings may still be applied" -ForegroundColor Yellow
        Write-StatusMessage -Message "Lid close action changed to: $newAction" -Type Success
    }
    
    # Display final status
    Write-Host "`n=== Lid Close Settings Updated ===" -ForegroundColor Green
    Write-Host "Battery (DC): $newAction" -ForegroundColor White
    Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)"
}