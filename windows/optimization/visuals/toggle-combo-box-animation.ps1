# Toggle "Slide open combo boxes" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether combo boxes have slide animation when opening

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
    # Combo box animation is controlled by SmoothScroll in HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    # Note: In Windows Performance Options, this is labeled as "Slide open combo boxes"
    # but the underlying registry value is SmoothScroll which also controls list box smooth scrolling
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "SmoothScroll"
    
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        Write-StatusMessage -Message "Creating registry path: $registryPath" -Type Info
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get current value (default to 1/enabled if not set)
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume it's enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming enabled (Windows default)" -Type Info
        $currentValue = 1
    }
    
    # Display current state
    $currentState = if ($currentValue -eq 1) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    # 1 = Enabled (slide open combo boxes)
    # 0 = Disabled (no slide animation for combo boxes)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    Write-StatusMessage -Message "Setting SmoothScroll to $newValue ($newState)..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord
    
    # Verify the change was applied
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Slide open combo boxes: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle combo box animation setting: $($_.Exception.Message)"
}
