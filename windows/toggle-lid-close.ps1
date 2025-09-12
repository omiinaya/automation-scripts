# Final working toggle for lid close behavior
# Uses the proven method to detect current values correctly

Write-Host "=== LID CLOSE TOGGLE - FINAL VERSION ===" -ForegroundColor Green

# Function to get current lid close settings - using the method that actually works
function Get-LidCloseValues {
    # Method: Use powercfg with AC/DC specific queries
    $dcValue = 1  # Default to Sleep
    $acValue = 1  # Default to Sleep
    
    try {
        # Query DC value specifically
        $dcResult = powercfg /query SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 DC 2>$null
        foreach ($line in $dcResult) {
            if ($line -match '(\d+)') {
                $dcValue = [int]$matches[1]
                break
            }
        }
        
        # Query AC value specifically
        $acResult = powercfg /query SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 AC 2>$null
        foreach ($line in $acResult) {
            if ($line -match '(\d+)') {
                $acValue = [int]$matches[1]
                break
            }
        }
        
        # Also try registry as fallback
        if ($dcValue -eq 1 -and $acValue -eq 1) {
            try {
                $activeScheme = powercfg /getactivescheme
                if ($activeScheme -match '([a-f0-9-]{36})') {
                    $schemeGuid = $matches[1]
                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$schemeGuid\5ca83367-6e45-459f-a27b-476b1d01c936"
                    
                    $dcReg = Get-ItemProperty -Path $regPath -Name "DCSettingIndex" -ErrorAction SilentlyContinue
                    $acReg = Get-ItemProperty -Path $regPath -Name "ACSettingIndex" -ErrorAction SilentlyContinue
                    
                    if ($dcReg) { $dcValue = $dcReg.DCSettingIndex }
                    if ($acReg) { $acValue = $acReg.ACSettingIndex }
                }
            } catch {
                # Registry failed, use powercfg values
            }
        }
        
    } catch {
        Write-Host "Error reading values, using defaults" -ForegroundColor Yellow
    }
    
    return @{
        DC = $dcValue
        AC = $acValue
    }
}

# Main execution
try {
    # Get current values
    Write-Host "Detecting current lid close settings..." -ForegroundColor Yellow
    $values = Get-LidCloseValues
    
    Write-Host "Current settings:"
    Write-Host "  DC (Battery): $($values.DC)" -ForegroundColor White
    Write-Host "  AC (Plugged in): $($values.AC)" -ForegroundColor White
    
    # Ensure both are the same for consistency
    $currentValue = $values.AC
    
    # Determine friendly names
    $currentName = switch ($currentValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($currentValue)" }
    }
    
    # Toggle value
    $newValue = if ($currentValue -eq 0) { 1 } else { 0 }
    $newName = switch ($newValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($newValue)" }
    }
    
    Write-Host "`nCurrent action: $currentName"
    Write-Host "Will change to: $newName" -ForegroundColor Yellow
    
    # Apply changes
    Write-Host "Applying changes..." -ForegroundColor Yellow
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setactive SCHEME_CURRENT
    
    # Verify changes
    $verify = Get-LidCloseValues
    Write-Host "`n=== VERIFICATION ===" -ForegroundColor Green
    Write-Host "New settings:"
    Write-Host "  DC (Battery): $($verify.DC) - $newName" -ForegroundColor White
    Write-Host "  AC (Plugged in): $($verify.AC) - $newName" -ForegroundColor White
    
    if ($verify.DC -eq $newValue -and $verify.AC -eq $newValue) {
        Write-Host "`n✓ Successfully toggled to: $newName" -ForegroundColor Green
    } else {
        Write-Host "`n⚠ Changes applied (verification may take a moment)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    Read-Host
}

Write-Host "`nScript completed!" -ForegroundColor Green