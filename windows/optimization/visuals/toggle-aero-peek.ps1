# Toggle Aero Peek effect on Windows
# Refactored to use modular system - reduces from 28 lines to 9 lines

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
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName "DesktopPreview" -DefaultValue 1
    $newValue = -not $currentValue
    
    Set-RegistryValue -KeyPath $registryPath -ValueName "DesktopPreview" -ValueData $newValue -ValueType DWord
    
    if ($newValue) {
        Write-StatusMessage -Message "Aero Peek enabled" -Type Success
    } else {
        Write-StatusMessage -Message "Aero Peek disabled" -Type Success
    }
    
    Write-StatusMessage -Message "Note: Changes may require restarting Windows Explorer or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Aero Peek: $($_.Exception.Message)"
}