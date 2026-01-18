# Toggle "Fade or slide menus into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETMENUFADE

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
    # SPI_GETMENUFADE = 0x1012, SPI_SETMENUFADE = 0x1013
    $SPI_GETMENUFADE = 0x1012
    $SPI_SETMENUFADE = 0x1013
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETMENUFADE, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current menu fade setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETMENUFADE, 0, [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply menu fade setting"
    }
    
    Write-StatusMessage -Message "Fade or slide menus into view: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle menu fade setting: $($_.Exception.Message)"
}
