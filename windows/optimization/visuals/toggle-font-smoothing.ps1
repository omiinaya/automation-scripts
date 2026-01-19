# Toggle "Smooth edges of screen fonts" setting with ClearType tuning
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with SPI_SETFONTSMOOTHING and SPI_SETFONTSMOOTHINGTYPE
# Also configures ClearType registry settings for proper font rendering

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # Add P/Invoke for SystemParametersInfo with different signatures
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SystemParams {
    // For getting/setting boolean values (font smoothing on/off)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoBool(uint uiAction, uint uiParam, ref bool pvParam, uint fWinIni);
    
    // For getting/setting DWORD values (font smoothing type)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoUInt(uint uiAction, uint uiParam, ref uint pvParam, uint fWinIni);
    
    // For setting values without return parameter (when pvParam is input, not output)
    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfoSet(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
}
"@

    # Constants for SystemParametersInfo
    $SPI_GETFONTSMOOTHING     = 0x004A
    $SPI_SETFONTSMOOTHING     = 0x004B
    $SPI_GETFONTSMOOTHINGTYPE = 0x200A
    $SPI_SETFONTSMOOTHINGTYPE = 0x200B
    $SPIF_UPDATEINIFILE       = 0x0001
    $SPIF_SENDCHANGE          = 0x0002
    
    # Get current font smoothing setting
    $currentSmoothing = $false
    $result = [SystemParams]::SystemParametersInfoBool($SPI_GETFONTSMOOTHING, 0, [ref]$currentSmoothing, 0)
    
    if (-not $result) {
        throw "Failed to get current font smoothing setting"
    }
    
    # Get current font smoothing type (ClearType vs Standard)
    $currentSmoothingType = 0
    $typeResult = [SystemParams]::SystemParametersInfoUInt($SPI_GETFONTSMOOTHINGTYPE, 0, [ref]$currentSmoothingType, 0)
    
    # Toggle the smoothing setting
    $newSmoothingValue = -not $currentSmoothing
    $newState = if ($newSmoothingValue) { "enabled" } else { "disabled" }
    
    # Apply the new smoothing setting
    $applyValue = if ($newSmoothingValue) { 1 } else { 0 }
    $result = [SystemParams]::SystemParametersInfoSet($SPI_SETFONTSMOOTHING, $applyValue, 0, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
    
    if (-not $result) {
        throw "Failed to apply font smoothing setting"
    }
    
    # Configure ClearType registry settings based on toggle state
    $avalonPath1 = "HKCU:\Software\Microsoft\Avalon.Graphics\DISPLAY1"
    $avalonPath2 = "HKCU:\Software\Microsoft\Avalon.Graphics\DISPLAY2"  # in case multi-monitor
    
    if ($newSmoothingValue) {
        # Enable ClearType - set registry values for optimal font rendering
        Write-StatusMessage -Message "Configuring ClearType tuning..." -Type Info
        
        # Create registry keys if they don't exist
        New-Item -Path $avalonPath1 -Force | Out-Null
        New-Item -Path $avalonPath2 -Force | Out-Null
        
        # Set ClearType tuning values for DISPLAY1
        Set-RegistryValue -KeyPath $avalonPath1 -ValueName "ClearTypeLevel" -ValueData 100 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath1 -ValueName "EnhancedContrastLevel" -ValueData 100 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath1 -ValueName "PixelStructure" -ValueData 1 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath1 -ValueName "TextContrastLevel" -ValueData 1 -ValueType DWord
        
        # Set ClearType tuning values for DISPLAY2 (multi-monitor)
        Set-RegistryValue -KeyPath $avalonPath2 -ValueName "ClearTypeLevel" -ValueData 100 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath2 -ValueName "EnhancedContrastLevel" -ValueData 100 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath2 -ValueName "PixelStructure" -ValueData 1 -ValueType DWord
        Set-RegistryValue -KeyPath $avalonPath2 -ValueName "TextContrastLevel" -ValueData 1 -ValueType DWord
        
        # Set font smoothing type to ClearType (2)
        [void][SystemParams]::SystemParametersInfoSet($SPI_SETFONTSMOOTHINGTYPE, 0, 2, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        Write-StatusMessage -Message "ClearType tuning applied" -Type Success
    } else {
        # Disable font smoothing - clear ClearType registry values
        Write-StatusMessage -Message "Clearing ClearType tuning..." -Type Info
        
        # Remove ClearType tuning values for DISPLAY1
        Remove-RegistryValue -KeyPath $avalonPath1 -ValueName "ClearTypeLevel" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath1 -ValueName "EnhancedContrastLevel" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath1 -ValueName "PixelStructure" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath1 -ValueName "TextContrastLevel" -ErrorAction SilentlyContinue
        
        # Remove ClearType tuning values for DISPLAY2
        Remove-RegistryValue -KeyPath $avalonPath2 -ValueName "ClearTypeLevel" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath2 -ValueName "EnhancedContrastLevel" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath2 -ValueName "PixelStructure" -ErrorAction SilentlyContinue
        Remove-RegistryValue -KeyPath $avalonPath2 -ValueName "TextContrastLevel" -ErrorAction SilentlyContinue
        
        # Set font smoothing type to Standard (0)
        [void][SystemParams]::SystemParametersInfoSet($SPI_SETFONTSMOOTHINGTYPE, 0, 0, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        Write-StatusMessage -Message "ClearType tuning cleared" -Type Success
    }
    
    # Also update registry settings for compatibility
    $desktopPath = "HKCU:\Control Panel\Desktop"
    if ($newSmoothingValue) {
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothing" -ValueData "2" -ValueType String
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothingType" -ValueData 2 -ValueType DWord
    } else {
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothing" -ValueData "0" -ValueType String
        Set-RegistryValue -KeyPath $desktopPath -ValueName "FontSmoothingType" -ValueData 0 -ValueType DWord
    }
    
    Write-StatusMessage -Message "Font smoothing: $newState" -Type Success
    
    # Refresh Explorer to apply changes immediately
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    Invoke-ExplorerRefresh
    
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle font smoothing setting: $($_.Exception.Message)"
}