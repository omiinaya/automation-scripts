# Script to fix all visual effects toggle scripts
# This script updates all the visual effects scripts to use the correct SystemParametersInfo calls

$scriptDir = Split-Path -Parent $PSScriptRoot

# Define the script fixes
$scriptFixes = @{
    "toggle-smooth-fonts.ps1" = @{
        GetSPI = 0x004A  # SPI_GETFONTSMOOTHING
        SetSPI = 0x004B  # SPI_SETFONTSMOOTHING
        Description = "Smooth edges of screen fonts"
        UseBool = $true
    }
    "toggle-shadows-under-windows.ps1" = @{
        GetSPI = 0x1024  # SPI_GETDROPSHADOW
        SetSPI = 0x1025  # SPI_SETDROPSHADOW
        Description = "Show shadows under windows"
        UseBool = $true
    }
    "toggle-shadows-under-mouse.ps1" = @{
        GetSPI = 0x101A  # SPI_GETCURSORSHADOW
        SetSPI = 0x101B  # SPI_SETCURSORSHADOW
        Description = "Show shadows under mouse pointer"
        UseBool = $true
    }
    "toggle-fade-menus.ps1" = @{
        GetSPI = 0x1012  # SPI_GETMENUFADE
        SetSPI = 0x1013  # SPI_SETMENUFADE
        Description = "Fade or slide menus into view"
        UseBool = $true
    }
    "toggle-fade-tooltips.ps1" = @{
        GetSPI = 0x1018  # SPI_GETTOOLTIPFADE
        SetSPI = 0x1019  # SPI_SETTOOLTIPFADE
        Description = "Fade or slide ToolTips into view"
        UseBool = $true
    }
    "toggle-fade-menu-items.ps1" = @{
        GetSPI = 0x1014  # SPI_GETSELECTIONFADE
        SetSPI = 0x1015  # SPI_SETSELECTIONFADE
        Description = "Fade out menu items after clicking"
        UseBool = $true
    }
    "toggle-smooth-scroll.ps1" = @{
        GetSPI = 0x1006  # SPI_GETLISTBOXSMOOTHSCROLLING
        SetSPI = 0x1007  # SPI_SETLISTBOXSMOOTHSCROLLING
        Description = "Smooth-scroll list boxes"
        UseBool = $true
    }
    "toggle-animate-controls.ps1" = @{
        GetSPI = 0x1002  # SPI_GETMENUANIMATION
        SetSPI = 0x1003  # SPI_SETMENUANIMATION
        Description = "Animate controls and elements inside windows"
        UseBool = $true
    }
}

Write-Host "Visual Effects Scripts Fix Utility" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

foreach ($scriptName in $scriptFixes.Keys) {
    $scriptPath = Join-Path $scriptDir $scriptName
    $fix = $scriptFixes[$scriptName]
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "SKIP: $scriptName (file not found)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Processing: $scriptName" -ForegroundColor White
    
    # Generate the new script content
    $newContent = @"
# Toggle "$($fix.Description)" setting
# This controls the checkbox in Performance Options > Visual Effects
# Uses SystemParametersInfo with proper SPI constants

# Function to pause on error
function Wait-OnError {
    param(
        [string]`$ErrorMessage
    )
    Write-Host "``nERROR: `$ErrorMessage" -ForegroundColor Red
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
`$modulePath = Join-Path `$PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module `$modulePath -Force -WarningAction SilentlyContinue

try {
    # SPI constants
    `$SPI_GET = 0x$($fix.GetSPI.ToString("X4"))
    `$SPI_SET = 0x$($fix.SetSPI.ToString("X4"))
    `$SPIF_UPDATEINIFILE = 0x0001
    `$SPIF_SENDCHANGE = 0x0002
    
    # Get current setting
    `$currentValue = `$false
    `$result = [SystemParams]::SystemParametersInfo(`$SPI_GET, 0, [ref]`$currentValue, 0)
    
    if (-not `$result) {
        throw "Failed to get current setting"
    }
    
    # Toggle the setting
    `$newValue = -not `$currentValue
    `$newState = if (`$newValue) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    `$result = [SystemParams]::SystemParametersInfo(`$SPI_SET, 0, [ref]`$newValue, `$SPIF_UPDATEINIFILE -bor `$SPIF_SENDCHANGE)
    
    if (-not `$result) {
        throw "Failed to apply setting"
    }
    
    Write-StatusMessage -Message "$($fix.Description): `$newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle setting: `$(`$_.Exception.Message)"
}
"@
    
    # Write the new content
    Set-Content -Path $scriptPath -Value $newContent -Encoding UTF8
    Write-Host "  FIXED: Updated to use SPI_GET=0x$($fix.GetSPI.ToString('X4')), SPI_SET=0x$($fix.SetSPI.ToString('X4'))" -ForegroundColor Green
}

Write-Host ""
Write-Host "Fix complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The following scripts require special handling and were not modified:" -ForegroundColor Yellow
Write-Host "  - toggle-taskbar-animations.ps1 (needs research on correct SPI constant)" -ForegroundColor Yellow
Write-Host "  - toggle-translucent-selection.ps1 (needs research on correct SPI constant)" -ForegroundColor Yellow
Write-Host "  - toggle-enable-peek.ps1 (uses DWM registry, not SPI)" -ForegroundColor Yellow
Write-Host "  - toggle-transparency.ps1 (uses DWM registry, not SPI)" -ForegroundColor Yellow
Write-Host "  - toggle-show-thumbnails.ps1 (uses Explorer registry, not SPI)" -ForegroundColor Yellow
Write-Host "  - toggle-taskbar-thumbnails.ps1 (uses Explorer registry, not SPI)" -ForegroundColor Yellow
Write-Host "  - toggle-icon-shadows.ps1 (uses Explorer registry, not SPI)" -ForegroundColor Yellow
