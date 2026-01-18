# Toggle transparency effects on Windows 11
# Refactored to use modular system - reduces from 28 lines to 9 lines

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
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName "EnableTransparency" -DefaultValue 1
    $newValue = -not $currentValue
    
    Set-RegistryValue -KeyPath $registryPath -ValueName "EnableTransparency" -ValueData $newValue -ValueType DWord
    
    # Broadcast WM_SETTINGCHANGE to apply changes immediately
    [SystemParams]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x0002) | Out-Null
    
    if ($newValue) {
        Write-StatusMessage -Message "Transparency effects enabled" -Type Success
    } else {
        Write-StatusMessage -Message "Transparency effects disabled" -Type Success
    }
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle transparency effects: $($_.Exception.Message)"
}