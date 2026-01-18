# Toggle "Show translucent selection rectangle" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x80 in second byte)

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
    $registryPath = "HKCU:\Control Panel\Desktop"
    $valueName = "UserPreferencesMask"
    
    # Get current UserPreferencesMask value (binary)
    $currentMask = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentMask) {
        throw "UserPreferencesMask value not found"
    }
    
    # Bit 0x80 in second byte (index 1) controls "Show translucent selection rectangle"
    # When bit is SET (1), translucent selection is ENABLED
    # When bit is CLEAR (0), translucent selection is DISABLED
    $translucentBit = 0x80
    
    # Check current state
    $isEnabled = ($currentMask[1] -band $translucentBit) -ne 0
    
    # Toggle the bit
    if ($isEnabled) {
        # Disable: Clear the bit
        $currentMask[1] = $currentMask[1] -band (-bnot $translucentBit)
        $newState = "disabled"
    } else {
        # Enable: Set the bit
        $currentMask[1] = $currentMask[1] -bor $translucentBit
        $newState = "enabled"
    }
    
    # Write back the modified mask
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $currentMask -Type Binary
    
    # Broadcast WM_SETTINGCHANGE to apply changes immediately
    [SystemParams]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x0002) | Out-Null
    
    Write-StatusMessage -Message "Show translucent selection rectangle: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle translucent selection setting: $($_.Exception.Message)"
}
