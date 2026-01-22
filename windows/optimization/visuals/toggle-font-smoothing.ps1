# Toggle "Smooth edges of screen fonts" setting with ClearType tuning
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETFONTSMOOTHING and SPI_SETFONTSMOOTHINGTYPE
# Also configures ClearType registry settings for proper font rendering

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
    # Add P/Invoke for SystemParametersInfo with different signatures
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SystemParams {
    // For getting/setting boolean values (font smoothing on/off)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoBool(uint uiAction, uint uiParam, ref bool pvParam, uint fWinIni);
    
    // For getting/setting DWORD values (font smoothing type)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoUInt(uint uiAction, uint uiParam, ref uint pvParam, uint fWinIni);
    
    // For setting values without return parameter (when pvParam is input, not output)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoSet(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
}
"@

    # Constants for SystemParametersInfo
    $SPI_GETFONTSMOOTHING = 0x004A
    $SPI_SETFONTSMOOTHING = 0x004B
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current font smoothing setting
    $currentSmoothing = $false
    $result = [SystemParams]::SystemParametersInfoBool($SPI_GETFONTSMOOTHING, 0, [ref]$currentSmoothing, 0)
    
    if (-not $result) {
        throw "Failed to get current font smoothing setting"
    }
    
    # Toggle the smoothing setting
    $newSmoothingValue = -not $currentSmoothing
    $newState = if ($newSmoothingValue) { "enabled" } else { "disabled" }
    
    # Apply the new smoothing setting
    $applyValue = if ($newSmoothingValue) { 1 } else { 0 }
    $result = [SystemParams]::SystemParametersInfoSet($SPI_SETFONTSMOOTHING, $applyValue, 0, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply font smoothing setting"
    }
    
    # Also update registry settings for compatibility
    $desktopPath = "HKCU:\Control Panel\Desktop"
    if ($newSmoothingValue) {
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothing" -ValueData "2" -ValueType String
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothingType" -ValueData 2 -ValueType DWord
    }
    else {
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothing" -ValueData "0" -ValueType String
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothingType" -ValueData 0 -ValueType DWord
    }
    
    Write-StatusMessage -Message "Font smoothing: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
}
catch {
    Wait-OnError -ErrorMessage "Failed to toggle font smoothing setting: $($_.Exception.Message)"
}