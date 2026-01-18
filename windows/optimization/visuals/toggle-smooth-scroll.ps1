# Toggle "Smooth-scroll list boxes" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETLISTBOXSMOOTHSCROLLING

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
    # SPI_GETLISTBOXSMOOTHSCROLLING = 0x1006, SPI_SETLISTBOXSMOOTHSCROLLING = 0x1007
    $SPI_GETLISTBOXSMOOTHSCROLLING = 0x1006
    $SPI_SETLISTBOXSMOOTHSCROLLING = 0x1007
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETLISTBOXSMOOTHSCROLLING, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current smooth scrolling setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETLISTBOXSMOOTHSCROLLING, 0, [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply smooth scrolling setting"
    }
    
    Write-StatusMessage -Message "Smooth-scroll list boxes: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle smooth scroll setting: $($_.Exception.Message)"
}
