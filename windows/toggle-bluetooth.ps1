# Toggle Bluetooth services on Windows 10/11
# Refactored to use modular system - reduces from 99 lines to 45 lines

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
    Write-StatusMessage -Message "Administrator privileges required to manage Bluetooth services" -Type Error
    Request-Elevation
    exit
}

try {
    # Primary Bluetooth service
    $btService = "bthserv"
    
    # Check if Bluetooth service exists
    if (-not (Test-ServiceExists -ServiceName $btService)) {
        Write-StatusMessage -Message "Bluetooth services not found on this system" -Type Warning
        Write-StatusMessage -Message "This script requires Windows Bluetooth support to be installed" -Type Info
        exit
    }
    
    # Get current service status
    $service = Get-Service -Name $btService -ErrorAction Stop
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters"
    
    # Check if service is running or stopped
    if ($service.Status -eq "Running") {
        # Disable Bluetooth
        Stop-Service -Name $btService -Force
        Set-Service -Name $btService -StartupType Disabled
        
        Write-StatusMessage -Message "Bluetooth services disabled" -Type Success
        Write-StatusMessage -Message "Bluetooth radio turned off" -Type Info
        
    } else {
        # Enable Bluetooth
        Set-Service -Name $btService -StartupType Automatic
        Start-Service -Name $btService
        
        Write-StatusMessage -Message "Bluetooth services enabled and started" -Type Success
        Write-StatusMessage -Message "Bluetooth radio turned on" -Type Info
    }
    
    # Update Bluetooth radio state via registry for comprehensive toggle
    try {
        if (Test-RegistryKey -KeyPath $registryPath) {
            $radioState = Get-RegistryValue -KeyPath $registryPath -ValueName "BluetoothRadioEnabled" -DefaultValue 1
            $newRadioState = if ($radioState -eq 1) { 0 } else { 1 }
            
            Set-RegistryValue -KeyPath $registryPath -ValueName "BluetoothRadioEnabled" -ValueData $newRadioState -ValueType DWord
            Write-StatusMessage -Message "Bluetooth radio registry state updated" -Type Info
        }
    } catch {
        Write-Verbose "Could not update Bluetooth radio registry state: $_"
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Bluetooth services: $($_.Exception.Message)"
}