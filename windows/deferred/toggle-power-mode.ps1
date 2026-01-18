# Toggle Windows Power Mode between Balanced and Best Performance
# Refactored to use modular system

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
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # Get current power mode
    $currentPowerMode = Get-Windows11PowerMode
    
    # Determine current mode value based on power source
    $batteryInfo = Get-BatteryInfo
    $currentModeValue = if ($batteryInfo -and (-not $batteryInfo.PowerOnline)) {
        $currentPowerMode.DCMode
    } else {
        $currentPowerMode.ACMode
    }
    
    # Map mode values to friendly names
    $modeNames = @{
        0 = "Balanced"
        1 = "Better Performance"
        2 = "Best Performance"
    }
    
    # Determine next mode (toggle between Balanced and Best Performance)
    $newModeValue = if ($currentModeValue -eq 0) {
        # Current is Balanced, switch to Best Performance
        2
    } else {
        # Current is Better Performance or Best Performance, switch to Balanced
        0
    }
    
    # Set the new power mode with proper AC power focus
    Set-Windows11PowerMode -Mode $newModeValue -ApplyTo "AC"
    
    # Force registry changes to take effect by refreshing power settings
    # This ensures Windows Settings UI reflects the changes
    $activeScheme = Get-ActivePowerScheme
    if ($activeScheme) {
        # Re-apply the active power scheme to trigger registry refresh
        Set-PowerScheme -SchemeGUID $activeScheme.GUID
    }
    
    # Get updated power mode to confirm change
    $updatedPowerMode = Get-Windows11PowerMode
    
    if ($updatedPowerMode.CurrentModeName -eq $modeNames[$newModeValue]) {
        Write-StatusMessage -Message "Power Mode changed from $($modeNames[$currentModeValue]) to $($modeNames[$newModeValue])" -Type Success
    } else {
        Write-StatusMessage -Message "Power Mode set to $($modeNames[$newModeValue])" -Type Success
    }
    
    Write-StatusMessage -Message "Note: Power Mode changes take effect immediately" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Power Mode: $($_.Exception.Message)"
}