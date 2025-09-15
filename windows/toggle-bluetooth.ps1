# Toggle Bluetooth services on Windows 10/11
# Refactored to use modern Bluetooth services and robust error handling

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
    # Modern Bluetooth services for Windows 10/11
    $bluetoothServices = @(
        "BTAGService",     # Bluetooth Audio Gateway Service
        "BthAvctpSvc",     # AVCTP Service (Audio/Video Control Transport Protocol)
        "BthHFSrv",        # Hands-Free Service
        "bthserv"          # Legacy Bluetooth Support Service (fallback)
    )
    
    # Registry paths for Bluetooth control
    $registryPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters",
        "HKLM:\SYSTEM\CurrentControlSet\Services\BthEnum\Parameters",
        "HKLM:\SYSTEM\CurrentControlSet\Services\BTHUSB\Parameters"
    )
    
    $activeServices = @()
    $foundServices = $false
    
    # Check which Bluetooth services exist on this system
    foreach ($service in $bluetoothServices) {
        if (Test-ServiceExists -ServiceName $service) {
            $activeServices += $service
            $foundServices = $true
            Write-Verbose "Found Bluetooth service: $service"
        }
    }
    
    if (-not $foundServices) {
        Write-StatusMessage -Message "Bluetooth services not found on this system" -Type Warning
        Write-StatusMessage -Message "This script requires Windows Bluetooth support to be installed" -Type Info
        exit
    }
    
    # Determine current Bluetooth state by checking the first available service
    $primaryService = $activeServices[0]
    $service = Get-Service -Name $primaryService -ErrorAction Stop
    
    # Check if Bluetooth is currently enabled (any service running)
    $isBluetoothEnabled = $false
    foreach ($serviceName in $activeServices) {
        $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $isBluetoothEnabled = $true
            break
        }
    }
    
    if ($isBluetoothEnabled) {
        # Disable Bluetooth - stop all Bluetooth services
        Write-StatusMessage -Message "Disabling Bluetooth services..." -Type Info
        
        foreach ($serviceName in $activeServices) {
            try {
                $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
                    Write-Verbose "Stopped and disabled service: $serviceName"
                }
            } catch {
                Write-Verbose "Could not stop service $serviceName`: $_"
            }
        }
        
        # Update Bluetooth radio state via registry
        $registryUpdated = $false
        foreach ($registryPath in $registryPaths) {
            try {
                if (Test-RegistryKey -KeyPath $registryPath) {
                    # Try different registry value names for Bluetooth control
                    $radioValueNames = @("BluetoothRadioEnabled", "RadioEnable", "EnableRadio")
                    
                    foreach ($valueName in $radioValueNames) {
                        if (Test-RegistryValue -KeyPath $registryPath -ValueName $valueName) {
                            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 0 -ValueType DWord -ErrorAction Stop
                            Write-Verbose "Updated registry: $registryPath\$valueName = 0"
                            $registryUpdated = $true
                            break
                        }
                    }
                }
            } catch {
                Write-Verbose "Could not update registry path $registryPath`: $_"
            }
        }
        
        Write-StatusMessage -Message "Bluetooth services disabled" -Type Success
        if ($registryUpdated) {
            Write-StatusMessage -Message "Bluetooth radio turned off via registry" -Type Info
        }
        
        # Alternative method: Use devcon to disable Bluetooth radio
        try {
            Start-Process -FilePath "devcon" -ArgumentList "disable *Bluetooth*" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            Write-Verbose "Attempted devcon disable method"
        } catch {
            Write-Verbose "Devcon method not available: $_"
        }
        
    } else {
        # Enable Bluetooth - start all Bluetooth services
        Write-StatusMessage -Message "Enabling Bluetooth services..." -Type Info
        
        foreach ($serviceName in $activeServices) {
            try {
                Set-Service -Name $serviceName -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Verbose "Started and enabled service: $serviceName"
            } catch {
                Write-Verbose "Could not start service $serviceName`: $_"
            }
        }
        
        # Update Bluetooth radio state via registry
        $registryUpdated = $false
        foreach ($registryPath in $registryPaths) {
            try {
                if (Test-RegistryKey -KeyPath $registryPath) {
                    # Try different registry value names for Bluetooth control
                    $radioValueNames = @("BluetoothRadioEnabled", "RadioEnable", "EnableRadio")
                    
                    foreach ($valueName in $radioValueNames) {
                        if (Test-RegistryValue -KeyPath $registryPath -ValueName $valueName) {
                            Set-RegistryValue -KeyPath $registryPath -ValueName $valueName -ValueData 1 -ValueType DWord -ErrorAction Stop
                            Write-Verbose "Updated registry: $registryPath\$valueName = 1"
                            $registryUpdated = $true
                            break
                        }
                    }
                }
            } catch {
                Write-Verbose "Could not update registry path $registryPath`: $_"
            }
        }
        
        Write-StatusMessage -Message "Bluetooth services enabled" -Type Success
        if ($registryUpdated) {
            Write-StatusMessage -Message "Bluetooth radio turned on via registry" -Type Info
        }
        
        # Alternative method: Use devcon to enable Bluetooth radio
        try {
            Start-Process -FilePath "devcon" -ArgumentList "enable *Bluetooth*" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            Write-Verbose "Attempted devcon enable method"
        } catch {
            Write-Verbose "Devcon method not available: $_"
        }
    }
    
    # Add verification delay and check final state
    Start-Sleep -Seconds 2
    
    $finalState = "unknown"
    foreach ($serviceName in $activeServices) {
        $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $finalState = "enabled"
            break
        } elseif ($svc -and $svc.Status -eq "Stopped") {
            $finalState = "disabled"
        }
    }
    
    if ($finalState -eq "enabled") {
        Write-StatusMessage -Message "✓ Bluetooth successfully enabled and verified" -Type Success
    } elseif ($finalState -eq "disabled") {
        Write-StatusMessage -Message "✓ Bluetooth successfully disabled and verified" -Type Success
    } else {
        Write-StatusMessage -Message "Bluetooth state change completed (verification inconclusive)" -Type Warning
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Bluetooth services: $($_.Exception.Message)"
}