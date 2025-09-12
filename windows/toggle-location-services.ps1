# Toggle location services on Windows 11
# Refactored to use modular system - reduces from 31 lines to 14 lines

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

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Request-Elevation
    exit
}

try {
    $locationService = Get-Service -Name "lfsvc" -ErrorAction Stop
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    $currentValue = Get-RegistryValue -KeyPath $registryPath -ValueName "Value" -DefaultValue "Allow"
    
    if ($currentValue -eq "Allow") {
        Set-RegistryValue -KeyPath $registryPath -ValueName "Value" -ValueData "Deny" -ValueType String
        Stop-Service -Name "lfsvc" -Force
        Write-StatusMessage -Message "Location services disabled" -Type Success
    } else {
        Set-RegistryValue -KeyPath $registryPath -ValueName "Value" -ValueData "Allow" -ValueType String
        Start-Service -Name "lfsvc"
        Write-StatusMessage -Message "Location services enabled" -Type Success
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle location services: $($_.Exception.Message)"
}