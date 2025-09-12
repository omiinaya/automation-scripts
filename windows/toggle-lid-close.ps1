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
    
    Write-Host "=== LID CLOSE TOGGLE DEBUGGING ===" -ForegroundColor Cyan
    Write-Host "Active Power Scheme: $powerScheme" -ForegroundColor Gray
    
    # Get current lid close settings using PowerManagement module
    try {
        $lidSetting = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
        
        if (-not $lidSetting) {
            throw "Failed to retrieve current lid close settings"
        }
        
        $currentDC = $lidSetting.DCValue
        $currentAC = $lidSetting.ACValue
        
        Write-Host "Retrieved via PowerManagement module:" -ForegroundColor Green
        Write-Host "  DC Value: $currentDC" -ForegroundColor White
        Write-Host "  AC Value: $currentAC" -ForegroundColor White
        
    } catch {
        Write-Host "PowerManagement module failed, falling back to direct parsing..." -ForegroundColor Yellow
        
        # Fallback to direct query with improved parsing
        $lidSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
        
        Write-Host "Raw powercfg output:" -ForegroundColor Gray
        $lidSettings | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        
        $currentDC = $null
        $currentAC = $null
        
        foreach ($line in $lidSettings) {
            if ($line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                $currentDC = Convert-HexStringToInt -HexString $matches[1]
                Write-Host "  Found DC: 0x$($matches[1]) → $currentDC" -ForegroundColor Green
            }
            if ($line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                $currentAC = Convert-HexStringToInt -HexString $matches[1]
                Write-Host "  Found AC: 0x$($matches[1]) → $currentAC" -ForegroundColor Green
            }
        }
        
        # Fail if parsing fails instead of using dangerous defaults
        if ($null -eq $currentDC -or $null -eq $currentAC) {
            throw @"
Failed to parse current lid close settings from powercfg output.
This is likely why the toggle isn't working correctly.

Please check:
1. Run 'powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID' manually
2. Ensure the output contains 'Current DC Power Setting Index' and 'Current AC Power Setting Index'
3. Check for any formatting differences

Raw output:
$($lidSettings -join "`n")
"@
        }
    }
    
    Write-Host "`n=== CURRENT STATE ===" -ForegroundColor Cyan
    Write-Host "DC: $currentDC, AC: $currentAC" -ForegroundColor White
    
    # Ensure both AC and DC values are consistent
    if ($currentDC -ne $currentAC) {
        Write-Host "Warning: Inconsistent AC/DC settings detected. Syncing both to the same value..." -ForegroundColor Yellow
        Write-Host "  DC: $currentDC → $currentAC (using AC value)" -ForegroundColor Gray
    }
    
    # Use the AC value as the reference for consistency
    $referenceValue = $currentAC
    
    # Toggle logic: 0 = Do nothing, 1 = Sleep, 2 = Hibernate, 3 = Shut down
    $newValue = if ($referenceValue -eq 0) { 1 } else { 0 }
    
    # Get friendly names for display
    $currentAction = switch ($referenceValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($referenceValue)" }
    }
    
    $newAction = switch ($newValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($newValue)" }
    }
    
    Write-Host "`n=== TOGGLE DECISION ===" -ForegroundColor Cyan
    Write-Host "Current: $currentAction (value: $referenceValue)" -ForegroundColor White
    Write-Host "Toggling to: $newAction (value: $newValue)" -ForegroundColor Green
    
    # Apply changes to both AC and DC
    Write-Host "Applying changes..." -ForegroundColor Gray
    powercfg /setdcvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    powercfg /setacvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    
    # Activate the changes
    Set-PowerScheme -SchemeGUID $powerScheme
    
    Write-Host "Verifying changes..." -ForegroundColor Gray
    
    # Verify the changes were applied using PowerManagement module
    try {
        $verification = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
        
        if (-not $verification) {
            throw "Failed to verify changes"
        }
        
        $verifiedDC = $verification.DCValue
        $verifiedAC = $verification.ACValue
        
        Write-Host "Verification results: DC=$verifiedDC, AC=$verifiedAC" -ForegroundColor Gray
        
    } catch {
        Write-Host "Verification failed, attempting fallback..." -ForegroundColor Yellow
        $verification = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
        
        $verifiedDC = $null
        $verifiedAC = $null
        
        foreach ($line in $verification) {
            if ($line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                $verifiedDC = Convert-HexStringToInt -HexString $matches[1]
            }
            if ($line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                $verifiedAC = Convert-HexStringToInt -HexString $matches[1]
            }
        }
    }
    
    # Strict verification - both values must match
    $verificationPassed = ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue)
    
    if ($verificationPassed) {
        Write-StatusMessage -Message "Successfully changed lid close action to: $newAction" -Type Success
    } else {
        Write-Host "ERROR: Verification failed!" -ForegroundColor Red
        Write-Host "Expected: DC=$newValue, AC=$newValue" -ForegroundColor Red
        Write-Host "Actual:   DC=$verifiedDC, AC=$verifiedAC" -ForegroundColor Red
        throw "Failed to apply lid close settings. Expected both AC and DC to be set to $newValue, but verification shows DC=$verifiedDC, AC=$verifiedAC"
    }
    
    # Display final status
    Write-Host "`n=== Lid Close Settings Updated ===" -ForegroundColor Green
    Write-Host "Battery (DC): $newAction" -ForegroundColor White
    Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)"
}