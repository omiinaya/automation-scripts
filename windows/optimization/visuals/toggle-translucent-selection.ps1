# Toggle "Show translucent selection rectangle" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether the selection rectangle has a translucent/alpha-blended appearance

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
    # The translucent selection rectangle is controlled by DWM AlphaSelectRect
    $registryPath = "HKCU:\Software\Microsoft\Windows\DWM"
    $valueName = "AlphaSelectRect"
    
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get current value (default to 1/enabled if not set)
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume it's enabled (Windows default)
        $currentValue = 1
    }
    
    # Toggle the setting
    # 1 = Enabled (translucent selection rectangle)
    # 0 = Disabled (opaque selection rectangle)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord
    
    # Restart DWM to apply changes immediately
    # Note: This will cause a brief screen flicker
    Write-StatusMessage -Message "Restarting Desktop Window Manager to apply changes..." -Type Info
    Restart-Service -Name "UxSms" -Force -ErrorAction SilentlyContinue
    
    Write-StatusMessage -Message "Show translucent selection rectangle: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied - DWM restarted" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle translucent selection setting: $($_.Exception.Message)"
}
