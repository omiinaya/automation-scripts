# Toggle "Save taskbar thumbnail previews" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether Windows saves taskbar thumbnail previews

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
    $registryPath = "HKCU:\Software\Microsoft\Windows\DWM"
    $valueName = "AlwaysHibernateThumbnails"
    
    # Get current value (1 = enabled, 0 = disabled)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue 0
    
    # Toggle the value
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType DWord
    
    Write-StatusMessage -Message "Save taskbar thumbnail previews: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting Windows Explorer or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle taskbar thumbnails setting: $($_.Exception.Message)"
}
