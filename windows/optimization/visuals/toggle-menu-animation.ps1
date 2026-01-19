# Toggle "Fade or slide menus into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether menus have fade/slide animations

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
    # Menu animation is controlled by UserPreferencesMask in HKCU:\Control Panel\Desktop
    # This is a bitmask value that controls multiple visual effects
    # We need to modify the bitmask to enable/disable menu animations
    # Windows 11 uses multiple registry locations for visual effects
    $registryPaths = @(
        "HKCU:\Control Panel\Desktop",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    )
    $valueName = "UserPreferencesMask"
    
    # Check if VisualFXSetting is overriding individual settings
    $visualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $visualFXValueName = "VisualFXSetting"
    
    # Get current VisualFXSetting value
    $visualFXValue = Get-ItemProperty -Path $visualFXPath -Name $visualFXValueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $visualFXValueName
    
    if ($visualFXValue -eq 3) {
        Write-StatusMessage -Message "VisualFXSetting is set to 3 (custom), allowing individual control" -Type Info
    } elseif ($visualFXValue -eq 2) {
        Write-StatusMessage -Message "VisualFXSetting is set to 2 (best appearance), individual settings may be overridden" -Type Warning
    } elseif ($visualFXValue -eq 1) {
        Write-StatusMessage -Message "VisualFXSetting is set to 1 (best performance), individual settings may be overridden" -Type Warning
    }
    
    # Ensure registry paths exist
    foreach ($path in $registryPaths) {
        if (-not (Test-Path $path)) {
            Write-StatusMessage -Message "Creating registry path: $path" -Type Info
            New-Item -Path $path -Force | Out-Null
        }
    }
    
    # Get current UserPreferencesMask value from primary location
    $currentValue = Get-ItemProperty -Path $registryPaths[0] -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume animations are enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming animations enabled (Windows default)" -Type Info
        $currentValue = [byte[]]@(156, 51, 7, 128, 0, 0, 0, 0, 192, 0, 0, 0)
    }
    
    # Check if menu animations are enabled (bit 0x40 in first byte)
    $menuAnimationsEnabled = ($currentValue[0] -band 0x40) -ne 0
    $currentState = if ($menuAnimationsEnabled) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the menu animation bit (bit 0x40)
    $newValue = $currentValue.Clone()
    if ($menuAnimationsEnabled) {
        # Disable menu animations
        $newValue[0] = $newValue[0] -band (-bnot 0x40)
    } else {
        # Enable menu animations
        $newValue[0] = $newValue[0] -bor 0x40
    }
    $newState = if (($newValue[0] -band 0x40) -ne 0) { "enabled" } else { "disabled" }
    
    # Apply the new setting to all registry locations
    foreach ($path in $registryPaths) {
        Write-StatusMessage -Message "Setting UserPreferencesMask to enable menu animations: $newState in $path..." -Type Info
        Set-ItemProperty -Path $path -Name $valueName -Value $newValue -Type Binary
    }
    
    # Verify the change was applied to primary location
    $verifyValue = Get-ItemProperty -Path $registryPaths[0] -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    # Compare only the relevant bit (0x40 in first byte) instead of entire array
    $expectedMenuAnimationsEnabled = ($newValue[0] -band 0x40) -ne 0
    $actualMenuAnimationsEnabled = ($verifyValue[0] -band 0x40) -ne 0
    if ($expectedMenuAnimationsEnabled -ne $actualMenuAnimationsEnabled) {
        throw "Registry value verification failed. Expected menu animations: $expectedMenuAnimationsEnabled, Got: $actualMenuAnimationsEnabled"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Fade or slide menus into view: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle menu animation setting: $($_.Exception.Message)"
}