# Toggle between light and dark mode on Windows 11
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

# Get current theme state
$appsTheme = (Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme")
$newThemeValue = (-not $appsTheme)

# Toggle theme settings
Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $newThemeValue
Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $newThemeValue

# Disable accent color on start and taskbar
Set-ItemProperty -Path $registryPath -Name "ColorPrevalence" -Value 0

# Restart Windows Explorer to apply changes immediately
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue