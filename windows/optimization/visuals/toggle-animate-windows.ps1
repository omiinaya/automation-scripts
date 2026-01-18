# Toggle "Animate windows when minimizing and maximizing" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x04)

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
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    $registryPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
    $valueName = "MinAnimate"
    
    # Get current value (1 = enabled, 0 = disabled)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "1"
    
    # Toggle the value
    if ($currentValue -eq "1") {
        $newValue = "0"
        $newState = "disabled"
    } else {
        $newValue = "1"
        $newState = "enabled"
    }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType String
    
    Write-StatusMessage -Message "Animate windows when minimizing and maximizing: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle animate windows setting: $($_.Exception.Message)"
}
