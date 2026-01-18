# Toggle "Fade or slide ToolTips into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETTOOLTIPFADE

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
    # SPI_GETTOOLTIPFADE = 0x1018, SPI_SETTOOLTIPFADE = 0x1019
    $SPI_GETTOOLTIPFADE = 0x1018
    $SPI_SETTOOLTIPFADE = 0x1019
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETTOOLTIPFADE, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current tooltip fade setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETTOOLTIPFADE, 0, [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply tooltip fade setting"
    }
    
    Write-StatusMessage -Message "Fade or slide ToolTips into view: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle tooltip fade setting: $($_.Exception.Message)"
}
