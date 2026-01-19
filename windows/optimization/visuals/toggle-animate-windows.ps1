# Toggle "Animate windows when minimizing and maximizing" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETANIMATION

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Add P/Invoke for SystemParametersInfo with ANIMATIONINFO structure
# Check if types already exist to avoid conflicts
if (-not ([System.Management.Automation.PSTypeName]'ANIMATIONINFO').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct ANIMATIONINFO
{
    public uint cbSize;
    public int iMinAnimate;
}
"@
}

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
    # SPI_GETANIMATION = 0x0048, SPI_SETANIMATION = 0x0049
    $SPI_GETANIMATION = 0x0048
    $SPI_SETANIMATION = 0x0049
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # Get the size of ANIMATIONINFO structure
    $size = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][ANIMATIONINFO])
    
    # Allocate memory for the structure
    $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
    
    try {
        # Initialize the structure
        $animationInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [Type][ANIMATIONINFO])
        $animationInfo.cbSize = $size
        [System.Runtime.InteropServices.Marshal]::StructureToPtr($animationInfo, $ptr, $false)
        
        # Get current setting
        $result = [SystemParams]::SystemParametersInfo($SPI_GETANIMATION, $size, $ptr, 0)
        
        if (-not $result) {
            throw "Failed to get current animation setting"
        }
        
        # Read the current value
        $currentInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [Type][ANIMATIONINFO])
        
        # Toggle the setting
        $newValue = if ($currentInfo.iMinAnimate -eq 0) { 1 } else { 0 }
        $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
        
        # Update the structure
        $currentInfo.iMinAnimate = $newValue
        [System.Runtime.InteropServices.Marshal]::StructureToPtr($currentInfo, $ptr, $false)
        
        # Apply the new setting
        $result = [SystemParams]::SystemParametersInfo($SPI_SETANIMATION, $size, $ptr, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        if (-not $result) {
            throw "Failed to apply animation setting"
        }
        
        Write-StatusMessage -Message "Animate windows when minimizing and maximizing: $newState" -Type Success
        
        # Refresh Explorer to apply changes immediately
        Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
        Invoke-ExplorerRefresh
        
        Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
        
    } finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle animate windows setting: $($_.Exception.Message)"
}
