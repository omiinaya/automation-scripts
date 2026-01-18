# Toggle "Show window contents while dragging" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether window contents are shown or just an outline when dragging

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
    # SPI_GETDRAGFULLWINDOWS = 0x0026, SPI_SETDRAGFULLWINDOWS = 0x0025
    $SPI_GETDRAGFULLWINDOWS = 0x0026
    $SPI_SETDRAGFULLWINDOWS = 0x0025
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETDRAGFULLWINDOWS, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current drag full windows setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETDRAGFULLWINDOWS, $(if ($newValue) { 1 } else { 0 }), [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply drag full windows setting"
    }
    
    Write-StatusMessage -Message "Show window contents while dragging: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle window contents dragging setting: $($_.Exception.Message)"
}
