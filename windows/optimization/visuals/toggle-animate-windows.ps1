# Toggle "Animate windows when minimizing and maximizing" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x04)

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Add P/Invoke for SystemParametersInfo and ANIMATIONINFO structure
# Check if types already exist to avoid conflicts
if (-not ([System.Management.Automation.PSTypeName]'ANIMATIONINFO').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct ANIMATIONINFO {
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
    
    # Get current animation settings
    $animInfo = New-Object ANIMATIONINFO
    $animInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($animInfo)
    
    # Allocate unmanaged memory for the struct
    $animInfoPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($animInfo.cbSize)
    [System.Runtime.InteropServices.Marshal]::StructureToPtr($animInfo, $animInfoPtr, $false)
    
    $result = [SystemParams]::SystemParametersInfo($SPI_GETANIMATION, 0, $animInfoPtr, 0)
    
    if (-not $result) {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($animInfoPtr)
        throw "Failed to get current animation settings"
    }
    
    # Read the struct back from unmanaged memory
    $animInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($animInfoPtr, [type]"ANIMATIONINFO")
    
    # Toggle the animation setting (iMinAnimate: 0 = disabled, 1 = enabled)
    if ($animInfo.iMinAnimate -ne 0) {
        $animInfo.iMinAnimate = 0
        $newState = "disabled"
    } else {
        $animInfo.iMinAnimate = 1
        $newState = "enabled"
    }
    
    # Update the struct in unmanaged memory
    [System.Runtime.InteropServices.Marshal]::StructureToPtr($animInfo, $animInfoPtr, $false)
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETANIMATION, 0, $animInfoPtr, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($animInfoPtr)
        throw "Failed to apply animation settings"
    }
    
    # Free the allocated memory
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($animInfoPtr)
    
    Write-StatusMessage -Message "Animate windows when minimizing and maximizing: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle animate windows setting: $($_.Exception.Message)"
}
