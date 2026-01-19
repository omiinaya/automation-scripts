# Toggle "Show window contents while dragging" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether window contents are visible during drag operations

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
    # Window contents dragging is controlled by DragFullWindows in HKCU:\Control Panel\Desktop
    # This is the registry value that Windows Performance Options reads
    $registryPath = "HKCU:\Control Panel\Desktop"
    $valueName = "DragFullWindows"
    
    # Also update the Explorer Advanced key for UI consistency
    $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
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
    # 1 = Enabled (show window contents while dragging)
    # 0 = Disabled (show outline only while dragging)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting to the primary registry location
    Write-StatusMessage -Message "Setting DragFullWindows to $newValue ($newState) in $registryPath..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type String
    
    # Also update Explorer Advanced key for UI consistency
    Write-StatusMessage -Message "Setting DragFullWindows to $newValue ($newState) in $explorerPath..." -Type Info
    Set-ItemProperty -Path $explorerPath -Name $valueName -Value $newValue -Type DWord
    
    # Verify the change was applied to primary location
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Show window contents while dragging: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle window contents dragging setting: $($_.Exception.Message)"
}
