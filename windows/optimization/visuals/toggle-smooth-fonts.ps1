# Toggle "Smooth edges of screen fonts" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls font smoothing (ClearType) on Windows

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
    $registryPath = "HKCU:\Control Panel\Desktop"
    $valueName = "FontSmoothing"
    
    # Get current value (2 = enabled, 0 = disabled)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue "2"
    
    # Toggle the value
    if ($currentValue -eq "2") {
        $newValue = "0"
        $newState = "disabled"
    } else {
        $newValue = "2"
        $newState = "enabled"
    }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType String
    
    Write-StatusMessage -Message "Smooth edges of screen fonts: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle smooth fonts setting: $($_.Exception.Message)"
}
