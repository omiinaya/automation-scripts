# Fixed toggle lid close behavior - handles the actual Windows powercfg format correctly
param(
    [switch]$DebugMode
)

if ($DebugMode) {
    Write-Host "=== DEBUG MODE ENABLED ===" -ForegroundColor Cyan
}

# Function to get current lid close settings using direct powercfg commands
function Get-LidCloseSettings {
    param(
        [string]$SchemeGUID = "SCHEME_CURRENT"
    )
    
    Write-Host "Getting lid close settings..." -ForegroundColor Yellow
    
    try {
        # Use the correct powercfg format: powercfg /query scheme subgroup setting
        $result = powercfg /query $SchemeGUID SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "First attempt failed, trying alternative format..." -ForegroundColor Yellow
            
            # Try querying all settings to find the correct format
            $allSettings = powercfg /query $SchemeGUID 2>&1
            
            $dcValue = $null
            $acValue = $null
            
            for ($i = 0; $i -lt $allSettings.Count; $i++) {
                $line = $allSettings[$i]
                
                # Look for the lid close setting specifically
                if ($line -match '5ca83367-6e45-459f-a27b-476b1d01c936|Lid.*close|Close.*lid') {
                    Write-Host "Found lid close setting at line $i: $line" -ForegroundColor Green
                    
                    # Look for the next few lines for values
                    for ($j = $i; $j -lt [Math]::Min($i+10, $allSettings.Count); $j++) {
                        $valueLine = $allSettings[$j]
                        
                        # More flexible regex for hex values
                        if ($valueLine -match '(?i)dc.*index.*0x([0-9a-f]+)') {
                            $dcValue = [Convert]::ToInt32($matches[1], 16)
                            Write-Host "  DC Value: $dcValue" -ForegroundColor Green
                        }
                        if ($valueLine -match '(?i)ac.*index.*0x([0-9a-f]+)') {
                            $acValue = [Convert]::ToInt32($matches[1], 16)
                            Write-Host "  AC Value: $acValue" -ForegroundColor Green
                        }
                    }
                    
                    if ($dcValue -ne $null -and $acValue -ne $null) {
                        return @{
                            DC = $dcValue
                            AC = $acValue
                            Success = $true
                        }
                    }
                }
            }
            
            # If we get here, use direct powercfg commands with known correct format
            $dcResult = powercfg /query $SchemeGUID SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 DC
            $acResult = powercfg /query $SchemeGUID SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 AC
            
            # Parse the numeric values from output
            $dcValue = 0
            $acValue = 0
            
            foreach ($line in $dcResult) {
                if ($line -match '\d+') {
                    $dcValue = [int]$matches[0]
                    break
                }
            }
            
            foreach ($line in $acResult) {
                if ($line -match '\d+') {
                    $acValue = [int]$matches[0]
                    break
                }
            }
            
            return @{
                DC = $dcValue
                AC = $acValue
                Success = $true
            }
            
        } else {
            # Parse the standard format
            $dcValue = 0
            $acValue = 0
            
            foreach ($line in $result) {
                Write-Host "  $line" -ForegroundColor DarkGray
                
                if ($line -match 'Current DC Power Setting Index:\s*0x([0-9a-fA-F]+)') {
                    $dcValue = [Convert]::ToInt32($matches[1], 16)
                }
                if ($line -match 'Current AC Power Setting Index:\s*0x([0-9a-fA-F]+)') {
                    $acValue = [Convert]::ToInt32($matches[1], 16)
                }
            }
            
            return @{
                DC = $dcValue
                AC = $acValue
                Success = $true
            }
        }
        
    } catch {
        Write-Host "Error getting lid close settings: $_" -ForegroundColor Red
        return @{
            DC = 0
            AC = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Function to set lid close settings
function Set-LidCloseSettings {
    param(
        [int]$NewValue,
        [string]$SchemeGUID = "SCHEME_CURRENT"
    )
    
    Write-Host "Setting lid close action to: $NewValue" -ForegroundColor Yellow
    
    try {
        # Use the correct powercfg commands
        $dcResult = powercfg /setdcvalueindex $SchemeGUID SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $NewValue 2>&1
        $acResult = powercfg /setacvalueindex $SchemeGUID SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $NewValue 2>&1
        $activeResult = powercfg /setactive $SchemeGUID 2>&1
        
        if ($DebugMode) {
            Write-Host "DC Result: $dcResult" -ForegroundColor Gray
            Write-Host "AC Result: $acResult" -ForegroundColor Gray
            Write-Host "Active Result: $activeResult" -ForegroundColor Gray
        }
        
        return $LASTEXITCODE -eq 0
    } catch {
        Write-Host "Error setting lid close settings: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    Write-Host "=== TOGGLE LID CLOSE BEHAVIOR ===" -ForegroundColor Green
    
    # Get current settings
    $current = Get-LidCloseSettings
    
    if (-not $current.Success) {
        Write-Host "Failed to get current lid close settings" -ForegroundColor Red
        exit 1
    }
    
    $currentDC = $current.DC
    $currentAC = $current.AC
    
    Write-Host "`nCurrent settings:"
    Write-Host "  DC (Battery): $currentDC" -ForegroundColor White
    Write-Host "  AC (Plugged in): $currentAC" -ForegroundColor White
    
    # Ensure both values are the same
    if ($currentDC -ne $currentAC) {
        Write-Host "Warning: DC and AC values are inconsistent, syncing to DC value..." -ForegroundColor Yellow
        $currentAC = $currentDC
    }
    
    # Toggle logic: 0 = Do nothing, 1 = Sleep
    $newValue = if ($currentAC -eq 0) { 1 } else { 0 }
    
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
    
    Write-Host "`nCurrent action: $currentAction"
    Write-Host "Will change to: $newAction" -ForegroundColor Yellow
    
    # Confirm before changing
    $confirmation = Read-Host "`nProceed with change? (y/n)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Change cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    # Apply the change
    $success = Set-LidCloseSettings -NewValue $newValue
    
    if ($success) {
        # Verify the change
        $verify = Get-LidCloseSettings
        if ($verify.Success -and $verify.AC -eq $newValue -and $verify.DC -eq $newValue) {
            Write-Host "`n✓ Successfully changed lid close action to: $newAction" -ForegroundColor Green
            Write-Host "  Battery (DC): $newAction" -ForegroundColor White
            Write-Host "  Plugged in (AC): $newAction" -ForegroundColor White
        } else {
            Write-Host "`n✗ Verification failed!" -ForegroundColor Red
            Write-Host "  Expected: DC=$newValue, AC=$newValue" -ForegroundColor Yellow
            Write-Host "  Found: DC=$($verify.DC), AC=$($verify.AC)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Failed to apply changes" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green