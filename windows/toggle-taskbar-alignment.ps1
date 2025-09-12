# Toggle taskbar alignment between left and center on Windows 11
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

try {
    # Get current taskbar alignment setting
    $taskbarAlValue = (Get-ItemPropertyValue -Path $registryPath -Name "TaskbarAl" -ErrorAction Stop)
    
    # Toggle between 0 (left) and 1 (center)
    $newAlignmentValue = if ($taskbarAlValue -eq 0) { 1 } else { 0 }
    
    # Set new alignment value
    Set-ItemProperty -Path $registryPath -Name "TaskbarAl" -Value $newAlignmentValue
    
    # Also set the TaskbarSi value which might be needed for proper alignment
    Set-ItemProperty -Path $registryPath -Name "TaskbarSi" -Value 0
    
    # Restart Windows Explorer to apply changes
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Write-Host "🔄 Windows Explorer restarted to apply changes" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️  Could not restart Windows Explorer automatically. Please restart Explorer manually or log off/on to apply changes." -ForegroundColor Yellow
    }
    
    # Provide feedback to user
    if ($newAlignmentValue -eq 1) {
        Write-Host "✅ Taskbar alignment set to CENTER" -ForegroundColor Green
    } else {
        Write-Host "✅ Taskbar alignment set to LEFT" -ForegroundColor Yellow
    }
    
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "❌ Registry path not found: $registryPath" -ForegroundColor Red
    Write-Host "This script requires Windows 11 and may not work on older versions." -ForegroundColor Red
} catch [System.Management.Automation.PSArgumentException] {
    # If the registry value doesn't exist, create it and set to center
    try {
        New-ItemProperty -Path $registryPath -Name "TaskbarAl" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path $registryPath -Name "TaskbarSi" -Value 0 -PropertyType DWORD -Force
        
        # Restart Explorer
        Stop-Process -Name "explorer" -Force
        
        Write-Host "✅ Taskbar alignment set to CENTER (registry values created)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create registry values: $($_.Exception.Message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
}