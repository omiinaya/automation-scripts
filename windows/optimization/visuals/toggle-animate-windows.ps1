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
Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct ANIMATIONINFO {
    public uint cbSize;
    public int iMinAnimate;
}

public class SystemParams {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
}
"@

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
    
    $result = [SystemParams]::SystemParametersInfo($SPI_GETANIMATION, $animInfo.cbSize, [ref]$animInfo, 0)
    
    if (-not $result) {
        throw "Failed to get current animation settings"
    }
    
    # Toggle the animation setting (iMinAnimate: 0 = disabled, 1 = enabled)
    if ($animInfo.iMinAnimate -ne 0) {
        $animInfo.iMinAnimate = 0
        $newState = "disabled"
    } else {
        $animInfo.iMinAnimate = 1
        $newState = "enabled"
    }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETANIMATION, $animInfo.cbSize, [ref]$animInfo, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply animation settings"
    }
    
    Write-StatusMessage -Message "Animate windows when minimizing and maximizing: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle animate windows setting: $($_.Exception.Message)"
}
