# Toggle "Slide open combo boxes" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls animation of combo boxes when opening

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
    # Combo box animation is controlled by the UserPreferencesMask binary value
    # Bit 0x20 controls combo box animation
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
    $comboBoxAnimationBit = 0x20
    $isEnabled = ($currentValue -band $comboBoxAnimationBit) -eq $comboBoxAnimationBit
    $currentState = if ($isEnabled) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    if ($isEnabled) {
        # Disable combo box animation
        $newValue = $currentValue -band (-bnot $comboBoxAnimationBit)
        $newState = "disabled"
    } else {
        # Enable combo box animation
        $newValue = $currentValue -bor $comboBoxAnimationBit
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
    
    Write-StatusMessage -Message "Slide open combo boxes: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle combo box animation setting: $($_.Exception.Message)"
}
