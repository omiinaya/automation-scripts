# Toggle taskbar alignment between left and center on Windows 11
# Refactored to use modular system - reduces from 50 lines to 15 lines

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
Import-Module $modulePath -Force

try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # Get current taskbar alignment
    $taskbarAlValue = Get-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -DefaultValue 0
    
    # Toggle between 0 (left) and 1 (center)
    $newAlignmentValue = if ($taskbarAlValue -eq 0) { 1 } else { 0 }
    
    # Apply changes
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -ValueData $newAlignmentValue -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarSi" -ValueData 0 -ValueType DWord
    
    # Restart Windows Explorer to apply changes
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Write-StatusMessage -Message "Windows Explorer restarted to apply changes" -Type Info
    } catch {
        Write-StatusMessage -Message "Could not restart Windows Explorer automatically. Please restart Explorer manually or log off/on to apply changes." -Type Warning
    }
    
    if ($newAlignmentValue -eq 1) {
        Write-StatusMessage -Message "Taskbar alignment set to CENTER" -Type Success
    } else {
        Write-StatusMessage -Message "Taskbar alignment set to LEFT" -Type Success
    }
    
} catch [System.Management.Automation.ItemNotFoundException] {
    Wait-OnError -ErrorMessage "Registry path not found. This script requires Windows 11."
} catch [System.Management.Automation.PSArgumentException] {
    # Create registry values if they don't exist
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarAl" -ValueData 1 -ValueType DWord
    Set-RegistryValue -KeyPath $registryPath -ValueName "TaskbarSi" -ValueData 0 -ValueType DWord
    Stop-Process -Name "explorer" -Force
    Write-StatusMessage -Message "Taskbar alignment set to CENTER (registry values created)" -Type Success
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle taskbar alignment: $($_.Exception.Message)"
}