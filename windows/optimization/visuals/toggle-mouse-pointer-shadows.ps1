# Toggle "Show shadows under mouse pointer" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether the mouse pointer has a shadow effect

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
    # The mouse pointer shadows are controlled by CursorShadow
    # This is the actual registry value that Performance Options UI modifies
    # Windows 11 uses multiple registry locations for visual effects
    $registryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
        "HKCU:\Control Panel\Desktop"
    )
    $valueName = "CursorShadow"
    
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
    
    # Get current value from primary location (default to 1/enabled if not set)
    $currentValue = Get-ItemProperty -Path $registryPaths[0] -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume it's enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming enabled (Windows default)" -Type Info
        $currentValue = 1
    }
    
    # Display current state
    $currentState = if ($currentValue -eq 1) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    # 1 = Enabled (shadows under mouse pointer)
    # 0 = Disabled (no shadows under mouse pointer)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting to all registry locations
    foreach ($path in $registryPaths) {
        Write-StatusMessage -Message "Setting CursorShadow to $newValue ($newState) in $path..." -Type Info
        Set-ItemProperty -Path $path -Name $valueName -Value $newValue -Type DWord
    }
    
    # Verify the change was applied to primary location
    $verifyValue = Get-ItemProperty -Path $registryPaths[0] -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Show shadows under mouse pointer: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle mouse pointer shadows setting: $($_.Exception.Message)"
}