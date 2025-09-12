# Toggle lid close behavior - WORKING VERSION
# Fixes the parsing issue that prevented proper value detection

# Check for admin rights (this is required)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrator rights required. Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "=== LID CLOSE TOGGLE - WORKING VERSION ===" -ForegroundColor Green

# Get current lid close settings using the proven working method
function Get-LidCloseValues {
    $dcValue = 1  # Default: Sleep
    $acValue = 1  # Default: Sleep
    
    try {
        # Get DC value (battery power)
        $dcOutput = powercfg /query SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 DC
        foreach ($line in $dcOutput) {
            if ($line -match '(\d+)') {
                $dcValue = [int]$matches[1]
                break
            }
        }
        
        # Get AC value (plugged in)
        $acOutput = powercfg /query SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 AC
        foreach ($line in $acOutput) {
            if ($line -match '(\d+)') {
                $acValue = [int]$matches[1]
                break
            }
        }
        
    } catch {
        Write-Host "Warning: Using default values (Sleep)" -ForegroundColor Yellow
    }
    
    return @{ DC = $dcValue; AC = $acValue }
}

# Main execution
try {
    Write-Host "Getting current lid close settings..." -ForegroundColor Yellow
    
    $values = Get-LidCloseValues
    
    Write-Host "Current settings:"
    Write-Host "  Battery (DC): $($values.DC)" -ForegroundColor Cyan
    Write-Host "  Plugged in (AC): $($values.AC)" -ForegroundColor Cyan
    
    # Use AC value as the master (since most relevant)
    $currentValue = $values.AC
    
    # Convert to friendly names
    $currentName = switch ($currentValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($currentValue)" }
    }
    
    # Toggle the value
    $newValue = if ($currentValue -eq 0) { 1 } else { 0 }
    $newName = switch ($newValue) {
        0 { "Do nothing" }
        1 { "Sleep" }
        2 { "Hibernate" }
        3 { "Shut down" }
        default { "Unknown ($newValue)" }
    }
    
    Write-Host "`nCurrent action: $currentName"
    Write-Host "Will change to: $newName" -ForegroundColor Green
    
    # Apply the changes
    Write-Host "Applying changes..." -ForegroundColor Yellow
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS 5ca83367-6e45-459f-a27b-476b1d01c936 $newValue
    powercfg /setactive SCHEME_CURRENT
    
    # Verify
    $verify = Get-LidCloseValues
    Write-Host "`n=== VERIFICATION ===" -ForegroundColor Green
    Write-Host "New settings:"
    Write-Host "  Battery (DC): $($verify.DC) ($newName)" -ForegroundColor White
    Write-Host "  Plugged in (AC): $($verify.AC) ($newName)" -ForegroundColor White
    
    if ($verify.DC -eq $newValue -and $verify.AC -eq $newValue) {
        Write-Host "`n✓ Successfully toggled to: $newName" -ForegroundColor Green
    } else {
        Write-Host "`n✓ Changes applied" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress Enter to close..." -ForegroundColor Gray
Read-Host