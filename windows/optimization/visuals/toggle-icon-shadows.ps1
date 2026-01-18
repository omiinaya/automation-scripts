# Toggle "Use drop shadows for icon labels on the desktop" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether desktop icon labels have drop shadows

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Add P/Invoke for SystemParametersInfo to broadcast settings changes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SystemParams {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "ListviewShadow"
    
    # Get current value (1 = enabled, 0 = disabled)
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName $valueName -DefaultValue 1
    
    # Toggle the value
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Write back the modified value
    Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData $newValue -ValueType DWord
    
    # Broadcast WM_SETTINGCHANGE to apply changes immediately
    [SystemParams]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x0002) | Out-Null
    
    Write-StatusMessage -Message "Use drop shadows for icon labels on the desktop: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle icon shadows setting: $($_.Exception.Message)"
}
