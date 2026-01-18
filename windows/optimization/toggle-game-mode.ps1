# Toggle Game Mode on Windows 11
# Refactored to use modular system

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
$modulePath = Join-Path $PSScriptRoot "..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    $registryPath = "HKCU:\Software\Microsoft\GameBar"
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName "AutoGameModeEnabled" -DefaultValue 1
    $newValue = -not $currentValue
    
    Set-RegistryValue -KeyPath $registryPath -ValueName "AutoGameModeEnabled" -ValueData $newValue -ValueType DWord
    
    if ($newValue) {
        Write-StatusMessage -Message "Game Mode enabled" -Type Success
    } else {
        Write-StatusMessage -Message "Game Mode disabled" -Type Success
    }
    
    Write-StatusMessage -Message "Note: Changes may require restarting games or applications to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Game Mode: $($_.Exception.Message)"
}