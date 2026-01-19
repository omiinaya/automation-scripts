# Toggle "Fade or slide ToolTips into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls fading or sliding of tooltips into view

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
    # Tooltip fade/slide is controlled by the UserPreferencesMask binary value
    # Bit 0x40 controls tooltip fade/slide animation
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
    $tooltipFadeBit = 0x40
    $isEnabled = ($currentValue -band $tooltipFadeBit) -eq $tooltipFadeBit
    $currentState = if ($isEnabled) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    if ($isEnabled) {
        # Disable tooltip fade/slide
        $newValue = $currentValue -band (-bnot $tooltipFadeBit)
        $newState = "disabled"
    } else {
        # Enable tooltip fade/slide
        $newValue = $currentValue -bor $tooltipFadeBit
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
    
    Write-StatusMessage -Message "Fade or slide ToolTips into view: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle tooltip fade setting: $($_.Exception.Message)"
}
