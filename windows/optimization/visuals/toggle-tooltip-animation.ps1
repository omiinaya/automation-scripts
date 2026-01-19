# Toggle "Fade or slide ToolTips into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether ToolTips have fade/slide animations

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
    # ToolTip animation is controlled by ToolTipAnimation in HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    # This is the actual registry value that Performance Options UI reads
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "ToolTipAnimation"
    
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
    # 1 = Enabled (ToolTip animations)
    # 0 = Disabled (no ToolTip animations)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    Write-StatusMessage -Message "Setting ToolTipAnimation to $newValue ($newState)..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord
    
    # Verify the change was applied
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Fade or slide ToolTips into view: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle ToolTip animation setting: $($_.Exception.Message)"
}
