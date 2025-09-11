# Toggle transparency effects on Windows 11
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

try {
    # Get current transparency setting
    $enableTransparency = (Get-ItemPropertyValue -Path $registryPath -Name "EnableTransparency" -ErrorAction Stop)
    $newTransparencyValue = (-not $enableTransparency)
    
    # Set new transparency value
    Set-ItemProperty -Path $registryPath -Name "EnableTransparency" -Value $newTransparencyValue
    
    # Provide feedback to user
    if ($newTransparencyValue) {
        Write-Host "✅ Transparency effects enabled" -ForegroundColor Green
    } else {
        Write-Host "✅ Transparency effects disabled" -ForegroundColor Yellow
    }
    
    Write-Host "Note: Changes may require restarting applications or signing out/in to take full effect" -ForegroundColor Cyan
    
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "❌ Registry path not found: $registryPath" -ForegroundColor Red
    Write-Host "This script requires Windows 10/11 and may not work on older versions." -ForegroundColor Red
} catch [System.Management.Automation.PSArgumentException] {
    Write-Host "❌ Required registry value not found. This script may not be compatible with your Windows version." -ForegroundColor Red
} catch {
    Write-Host "❌ An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
}