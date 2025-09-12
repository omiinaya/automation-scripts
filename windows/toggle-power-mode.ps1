# Toggle between Windows 11 Power Modes: Recommended, Better Performance, and Best Performance
# Updated to use Windows 11's registry-based Power Mode settings instead of legacy power schemes

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
    Write-Host "`n=== Windows 11 Power Mode Toggle ===" -ForegroundColor Cyan
    Write-Host "This script toggles between Windows 11 Power Modes via registry settings" -ForegroundColor Gray
    
    # Get current Windows 11 Power Mode
    $currentPowerMode = Get-Windows11PowerMode
    
    Write-Host "`nCurrent power mode: " -NoNewline
    Write-Host $currentPowerMode.CurrentModeName -ForegroundColor Cyan
    
    # Show AC/DC values if different
    if ($currentPowerMode.ACMode -ne $currentPowerMode.DCMode) {
        Write-Host "  AC Power:  " -NoNewline
        Write-Host $currentPowerMode.ACModes[[string]$currentPowerMode.ACMode] -ForegroundColor Yellow
        Write-Host "  DC Power:  " -NoNewline
        Write-Host $currentPowerMode.ACModes[[string]$currentPowerMode.DCMode] -ForegroundColor Yellow
    }
    
    # Determine next mode (cycle through 0, 1, 2)
    $batteryInfo = Get-BatteryInfo
    $currentModeValue = if ($batteryInfo -and (-not $batteryInfo.PowerOnline)) {
        $currentPowerMode.DCMode
    } else {
        $currentPowerMode.ACMode
    }
    
    $nextModeValue = ($currentModeValue + 1) % 3
    $modeNames = @{
        0 = "Recommended"
        1 = "Better Performance"
        2 = "Best Performance"
    }
    
    $nextModeName = $modeNames[$nextModeValue]
    
    Write-Host "`nSwitching to: " -NoNewline
    Write-Host $nextModeName -ForegroundColor Green
    
    # Set the new power mode
    Set-Windows11PowerMode -Mode $nextModeValue
    
    # Verify the change
    $newPowerMode = Get-Windows11PowerMode
    if ($newPowerMode.CurrentModeName -eq $nextModeName) {
        Write-StatusMessage -Message "Power mode successfully changed to: $nextModeName" -Type Success
        
        # Show detailed information
        Write-Host "`nPower Mode Details:" -ForegroundColor Yellow
        Write-Host "Registry Value: $nextModeValue" -ForegroundColor Gray
        Write-Host "Mode Name: $nextModeName" -ForegroundColor Gray
        
        # Show power source info
        if ($batteryInfo) {
            Write-Host "`nPower Source: " -NoNewline
            if ($batteryInfo.PowerOnline) {
                Write-Host "AC Power (Plugged in)" -ForegroundColor Green
            } else {
                Write-Host "DC Power (On battery)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-StatusMessage -Message "Power mode change may not have been applied correctly" -Type Warning
    }
    
    # Show battery information if available
    if ($batteryInfo) {
        Write-Host "`nBattery Information:" -ForegroundColor Yellow
        Write-Host "Charge Level: $($batteryInfo.ChargeLevel)%"
        Write-Host "Status: $($batteryInfo.Status)"
        if ($batteryInfo.EstimatedRuntime -gt 0) {
            Write-Host "Estimated Runtime: $($batteryInfo.EstimatedRuntime) minutes"
        }
    }
    
    Write-Host "`nPower mode toggle complete!" -ForegroundColor Green
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Windows 11 Power Mode: $($_.Exception.Message)"
}