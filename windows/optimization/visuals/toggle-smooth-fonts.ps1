# Toggle "Smooth edges of screen fonts" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETFONTSMOOTHING

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Add P/Invoke for SystemParametersInfo
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SystemParams {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref bool pvParam, uint fWinIni);
}
"@

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # SPI_GETFONTSMOOTHING = 0x004A, SPI_SETFONTSMOOTHING = 0x004B
    $SPI_GETFONTSMOOTHING = 0x004A
    $SPI_SETFONTSMOOTHING = 0x004B
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETFONTSMOOTHING, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current font smoothing setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETFONTSMOOTHING, $(if ($newValue) { 1 } else { 0 }), [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply font smoothing setting"
    }
    
    Write-StatusMessage -Message "Smooth edges of screen fonts: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle smooth fonts setting: $($_.Exception.Message)"
}
