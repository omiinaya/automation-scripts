# Toggle between light and dark mode on Windows 11
# Refactored to use modular system - reduces from 38 lines to 12 lines

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
$modulePath = Join-Path $PSScriptRoot "modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    # Get current theme state
    $appsTheme = Get-RegistryValue -KeyPath $registryPath -ValueName "AppsUseLightTheme" -DefaultValue 1
    $newThemeValue = -not $appsTheme
    
    # Apply theme changes
    Set-RegistryValue -KeyPath $registryPath -ValueName "AppsUseLightTheme" -ValueData $newThemeValue -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "SystemUsesLightTheme" -ValueData $newThemeValue -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "ColorPrevalence" -ValueData 0 -ValueType DWord
    
    if ($newThemeValue) {
        Write-StatusMessage -Message "Windows theme changed to DARK mode" -Type Success
    } else {
        Write-StatusMessage -Message "Windows theme changed to LIGHT mode" -Type Success
    }
    
    # Restart Windows Explorer to apply changes
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Write-StatusMessage -Message "Windows Explorer restarted to apply changes" -Type Info
    } catch {
        Write-StatusMessage -Message "Could not restart Windows Explorer automatically. Please restart Explorer manually or log off/on to apply changes." -Type Warning
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle theme: $($_.Exception.Message)"
}