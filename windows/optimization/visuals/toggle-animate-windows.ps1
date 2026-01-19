# Toggle "Animate windows when minimizing and maximizing" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls animation of windows when minimizing and maximizing

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
    # This setting is controlled by the UserPreferencesMask binary value
    # Bit 0x04 controls window animation
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $valueName = "UserPreferencesMask"
    
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        Write-StatusMessage -Message "Creating registry path: $registryPath" -Type Info
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get current value (default to enabled if not set)
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume it's enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming enabled (Windows default)" -Type Info
        $currentValue = 0x90  # Default value with animations enabled
    }
    
    # Display current state
    $windowAnimationBit = 0x04
    $isEnabled = ($currentValue -band $windowAnimationBit) -eq $windowAnimationBit
    $currentState = if ($isEnabled) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    if ($isEnabled) {
        # Disable window animation
        $newValue = $currentValue -band (-bnot $windowAnimationBit)
        $newState = "disabled"
    } else {
        # Enable window animation
        $newValue = $currentValue -bor $windowAnimationBit
        $newState = "enabled"
    }
    
    # Apply the new setting
    Write-StatusMessage -Message "Setting UserPreferencesMask to $($newValue.ToString('X')) ($newState)..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type Binary
    
    # Verify the change was applied
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $($newValue.ToString('X')), Got: $($verifyValue.ToString('X'))"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Animate windows when minimizing and maximizing: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle animate windows setting: $($_.Exception.Message)"
}
