# Toggle "Show window contents while dragging" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether window contents are shown or just an outline when dragging

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
    $valueName = "DragFullWindows"
    
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
    
    Write-StatusMessage -Message "Show window contents while dragging: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle window contents dragging setting: $($_.Exception.Message)"
}
