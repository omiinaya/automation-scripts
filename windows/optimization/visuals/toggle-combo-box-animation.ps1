# Toggle "Slide open combo boxes" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETCOMBOBOXANIMATION

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
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref bool pvParam, uint fWinIni);
}
"@
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # SPI_GETUIEFFECTS = 0x103E, SPI_SETUIEFFECTS = 0x103F
    $SPI_GETUIEFFECTS = 0x103E
    $SPI_SETUIEFFECTS = 0x103F
    $SPI_GETCOMBOBOXANIMATION = 0x1004
    $SPI_SETCOMBOBOXANIMATION = 0x1005
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    
    # First, ensure UI effects are enabled (master switch)
    $uiEffectsValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETUIEFFECTS, 0, [ref]$uiEffectsValue, 0)
    
    if (-not $result) {
        throw "Failed to get UI effects setting"
    }
    
    # Enable UI effects if disabled
    if (-not $uiEffectsValue) {
        $uiEffectsValue = $true
        $result = [SystemParams]::SystemParametersInfo($SPI_SETUIEFFECTS, 0, [ref]$uiEffectsValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        if (-not $result) {
            throw "Failed to enable UI effects"
        }
        Write-StatusMessage -Message "Enabled UI effects (required for combo box animation)" -Type Info
    }
    
    # Get current combo box animation setting
    $currentValue = $false
    $result = [SystemParams]::SystemParametersInfo($SPI_GETCOMBOBOXANIMATION, 0, [ref]$currentValue, 0)
    
    if (-not $result) {
        throw "Failed to get current combo box animation setting"
    }
    
    # Toggle the setting
    $newValue = -not $currentValue
    $newState = if ($newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    $result = [SystemParams]::SystemParametersInfo($SPI_SETCOMBOBOXANIMATION, 0, [ref]$newValue, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply combo box animation setting"
    }
    
    Write-StatusMessage -Message "Slide open combo boxes: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle combo box animation setting: $($_.Exception.Message)"
}
