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
# Check if type already exists to avoid conflicts
if (-not ([System.Management.Automation.PSTypeName]'SystemParams').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SystemParams {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # SPI_GETDRAGFULLWINDOWS = 0x0026, SPI_SETDRAGFULLWINDOWS = 0x0025
    $SPI_GETDRAGFULLWINDOWS = 0x0026
    $SPI_SETDRAGFULLWINDOWS = 0x0025
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Allocate memory for boolean value
    $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)  # sizeof(int)
    
    try {
        # Get current setting
        $result = [SystemParams]::SystemParametersInfo($SPI_GETDRAGFULLWINDOWS, 0, $ptr, 0)
        
        if (-not $result) {
            throw "Failed to get current drag full windows setting"
        }
        
        # Read the current value
        $currentValue = [System.Runtime.InteropServices.Marshal]::ReadInt32($ptr)
        $currentValue = $currentValue -ne 0  # Convert to boolean
        
        # Toggle the setting
        $newValue = -not $currentValue
        $newState = if ($newValue) { "enabled" } else { "disabled" }
        
        # Write the new value
        [System.Runtime.InteropServices.Marshal]::WriteInt32($ptr, [int]$newValue)
        
        # Apply the new setting
        $result = [SystemParams]::SystemParametersInfo($SPI_SETDRAGFULLWINDOWS, 0, $ptr, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        if (-not $result) {
            throw "Failed to apply drag full windows setting"
        }
    } finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
    }
    
    Write-StatusMessage -Message "Show window contents while dragging: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle window contents dragging setting: $($_.Exception.Message)"
}
