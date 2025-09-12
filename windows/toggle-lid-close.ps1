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
    
    # Try multiple subgroup GUIDs to find the correct one
    $subgroupGUIDsToTry = @(
        "4f971e89-eebd-4455-a8de-9e59040e7347",  # SUB_BUTTONS
        "0012ee47-9041-4b5d-9b77-535fba8b1442",  # Alternative SUB_BUTTONS
        "238c9fa8-0aad-41ed-83f4-97be242c8f20"   # SUB_SLEEP (fallback)
    )
    
    $powerSettingSubgroup = $null
    $currentDC = $null
    $currentAC = $null
    
    Write-Host "Searching for correct subgroup GUID..." -ForegroundColor Yellow
    
    foreach ($subgroup in $subgroupGUIDsToTry) {
        Write-Host "  Testing subgroup: $subgroup" -ForegroundColor Gray
        
        try {
            $queryResult = powercfg /query $powerScheme $subgroup $lidCloseGUID 2>$null
            if ($LASTEXITCODE -eq 0 -and $queryResult -match "Current AC Power Setting Index") {
                Write-Host "  ✓ Found valid subgroup: $subgroup" -ForegroundColor Green
                
                $powerSettingSubgroup = $subgroup
                foreach ($line in $queryResult) {
                    if ($line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                        $currentDC = Convert-HexStringToInt -HexString $matches[1]
                    }
                    if ($line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
                        $currentAC = Convert-HexStringToInt -HexString $matches[1]
                    }
                }
                
                if ($null -ne $currentDC -and $null -ne $currentAC) {
                    Write-Host "    Current values: DC=$currentDC, AC=$currentAC" -ForegroundColor Green
                    break
                }
            }
        } catch {
            Write-Host "  ✗ Failed for subgroup $subgroup" -ForegroundColor Red
        }
    }
    
    if ($null -eq $powerSettingSubgroup) {
        throw "Could not find a valid subgroup GUID for lid close settings. Available subgroups may differ by Windows version."
    }
    
    # Also try the PowerManagement module as a secondary verification
    Write-Host "`nVerifying with PowerManagement module..." -ForegroundColor Yellow
    try {
        $lidSetting = Get-PowerSetting -SettingGUID $lidCloseGUID -PowerSchemeGUID $powerScheme
        if ($lidSetting -and $lidSetting.DCValue -ne $null -and $lidSetting.ACValue -ne $null) {
            Write-Host "  PowerManagement module values: DC=$($lidSetting.DCValue), AC=$($lidSetting.ACValue)" -ForegroundColor Green
            if ($lidSetting.DCValue -eq $currentDC -and $lidSetting.ACValue -eq $currentAC) {
                Write-Host "  ✓ Values match direct query" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Values differ - using direct query values" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  PowerManagement module failed, using direct query" -ForegroundColor Yellow
    }
    
    Write-Host "Successfully parsed: DC=$currentDC, AC=$currentAC" -ForegroundColor Green
    
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
    
    # Verify the changes were applied with enhanced diagnostics
    $verification = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    Write-Host "`n=== VERIFICATION ===" -ForegroundColor Cyan
    Write-Host "Querying: powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID" -ForegroundColor Gray
    
    $verifiedDC = $null
    $verifiedAC = $null
    
    foreach ($line in $verification) {
        Write-Host "  $line" -ForegroundColor DarkGray
        if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedDC = Convert-HexStringToInt -HexString $matches[1]
            Write-Host "    DC Value: 0x$($matches[1]) -> $verifiedDC" -ForegroundColor Green
        }
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedAC = Convert-HexStringToInt -HexString $matches[1]
            Write-Host "    AC Value: 0x$($matches[1]) -> $verifiedAC" -ForegroundColor Green
        }
    }
    
    # Handle verification failures gracefully
    if ($null -eq $verifiedDC) {
        $verifiedDC = -1
        Write-Host "    DC: Could not be determined" -ForegroundColor Red
    }
    if ($null -eq $verifiedAC) {
        $verifiedAC = -1
        Write-Host "    AC: Could not be determined" -ForegroundColor Red
    }
    
    # Strict verification - both must match
    $verificationPassed = ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue)
    
    if ($verificationPassed) {
        Write-StatusMessage -Message "✓ Successfully changed lid close action to: $newAction" -Type Success
    } else {
        Write-Host "`n✗ Verification failed!" -ForegroundColor Red
        Write-Host "Expected: AC=$newValue, DC=$newValue" -ForegroundColor Yellow
        Write-Host "Found:    AC=$verifiedAC, DC=$verifiedDC" -ForegroundColor Yellow
        Write-Host "This may indicate the wrong subgroup GUID or other configuration issue." -ForegroundColor Red
    }
    
    # Display final status
    Write-Host "`n=== Lid Close Settings Updated ===" -ForegroundColor Green
    Write-Host "Battery (DC): $newAction" -ForegroundColor White
    Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)"
}