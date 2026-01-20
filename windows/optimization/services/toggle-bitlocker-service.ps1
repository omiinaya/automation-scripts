# Toggle BitLocker Drive Encryption service (BDESVC) startup type on Windows
# Enable/Disable service startup instead of starting/stopping the service
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
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Host "`nWARNING: This operation may require administrator privileges" -ForegroundColor Yellow
        Write-Host "Some service operations may fail without elevated permissions" -ForegroundColor Yellow
    }
    
    # Get current service status
    $service = Get-Service -Name "BDESVC" -ErrorAction SilentlyContinue
    
    if (-not $service) {
        Write-StatusMessage -Message "BitLocker Drive Encryption service (BDESVC) not found on this system" -Type Warning
        Write-StatusMessage -Message "This service may not be available on your Windows version" -Type Info
        Write-StatusMessage -Message "No action taken" -Type Info
        return
    }
    
    Write-StatusMessage -Message "Current BitLocker service status: $($service.Status)" -Type Info
    Write-StatusMessage -Message "Current startup type: $($service.StartType)" -Type Info
    
    # Determine action based on current startup type
    if ($service.StartType -eq "Disabled") {
        # Enable the service (set to Manual) and start it
        Set-Service -Name "BDESVC" -StartupType "Manual" -ErrorAction Stop
        Start-Service -Name "BDESVC" -ErrorAction Stop
        Write-StatusMessage -Message "BitLocker Drive Encryption service enabled and started" -Type Success
        Write-StatusMessage -Message "BitLocker functionality is now available" -Type Warning
        Write-StatusMessage -Message "Note: BitLocker provides full-disk encryption for data protection" -Type Info
    } else {
        # Disable the service and stop it
        Stop-Service -Name "BDESVC" -ErrorAction Stop
        Set-Service -Name "BDESVC" -StartupType "Disabled" -ErrorAction Stop
        Write-StatusMessage -Message "BitLocker Drive Encryption service stopped and disabled" -Type Success
        Write-StatusMessage -Message "BitLocker functionality is now disabled" -Type Warning
        Write-StatusMessage -Message "Note: Disabling BitLocker removes full-disk encryption security" -Type Warning
    }
    
    # Verify the new startup type
    Start-Sleep -Seconds 2
    $newService = Get-Service -Name "BDESVC"
    Write-StatusMessage -Message "New BitLocker service startup type: $($newService.StartType)" -Type Info
    Write-StatusMessage -Message "Current service status: $($newService.Status)" -Type Info
    
    Write-StatusMessage -Message "Note: Startup type changes require a reboot to take full effect" -Type Warning
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle BitLocker Drive Encryption service startup type: $($_.Exception.Message)"
}