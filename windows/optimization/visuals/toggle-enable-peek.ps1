# Toggle "Enable Peek" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls Aero Peek functionality (desktop preview when hovering over taskbar)

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
    $valueName = "EnableAeroPeek"
    
    # Get current value (1 = enabled, 0 = disabled)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue 1
    
    # Toggle the value
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType DWord
    
    Write-StatusMessage -Message "Enable Peek: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting Windows Explorer or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Enable Peek setting: $($_.Exception.Message)"
}
