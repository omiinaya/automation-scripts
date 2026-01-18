# Toggle "Show thumbnails instead of icons" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether Windows Explorer shows thumbnail previews for images and videos

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
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "IconsOnly"
    
    # Get current value (0 = thumbnails enabled, 1 = icons only)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue 0
    
    # Toggle the value (note: this is inverted logic)
    $newValue = if ($currentValue -eq 0) { 1 } else { 0 }
    $newState = if ($newValue -eq 0) { "enabled (thumbnails)" } else { "disabled (icons only)" }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType DWord
    
    Write-StatusMessage -Message "Show thumbnails instead of icons: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting Windows Explorer or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle show thumbnails setting: $($_.Exception.Message)"
}
