# Toggle between light and dark mode on Windows 11
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

try {
    # Get current theme state
    $appsTheme = (Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction Stop)
    $newThemeValue = (-not $appsTheme)
    
    # Toggle theme settings
    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $newThemeValue
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $newThemeValue
    
    # Disable accent color on start and taskbar
    Set-ItemProperty -Path $registryPath -Name "ColorPrevalence" -Value 0
    
    # Provide feedback to user
    if ($newThemeValue) {
        Write-Host "✅ Windows theme changed to DARK mode" -ForegroundColor Green
    } else {
        Write-Host "✅ Windows theme changed to LIGHT mode" -ForegroundColor Yellow
    }
    
    # Restart Windows Explorer to apply changes immediately
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Write-Host "🔄 Windows Explorer restarted to apply changes" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️  Could not restart Windows Explorer automatically. Please restart Explorer manually or log off/on to apply changes." -ForegroundColor Red
    }
    
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "❌ Registry path not found: $registryPath" -ForegroundColor Red
    Write-Host "This script requires Windows 10/11 and may not work on older versions." -ForegroundColor Red
} catch [System.Management.Automation.PSArgumentException] {
    Write-Host "❌ Required registry values not found. This script may not be compatible with your Windows version." -ForegroundColor Red
} catch {
    Write-Host "❌ An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
}