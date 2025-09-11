# Toggle between light and dark mode on Windows 11 (including taskbar)
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$appsTheme = (Get-ItemPropertyValue -Path $registryPath -Name "AppsUseLightTheme")
Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value (-not $appsTheme)
Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value (-not $appsTheme)