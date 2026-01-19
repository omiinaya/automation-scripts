# Toggle Geolocation service (lfsvc) startup type on Windows
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
    $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    
    if (-not $service) {
        Write-StatusMessage -Message "Geolocation service (lfsvc) not found on this system" -Type Warning
        Write-StatusMessage -Message "This service may not be available on your Windows version" -Type Info
        Write-StatusMessage -Message "No action taken" -Type Info
        return
    }
    
    Write-StatusMessage -Message "Current Geolocation service status: $($service.Status)" -Type Info
    Write-StatusMessage -Message "Current startup type: $($service.StartType)" -Type Info
    
    # Determine action based on current startup type
    if ($service.StartType -eq "Disabled") {
        # Enable the service (set to Manual) and start it
        Set-Service -Name "lfsvc" -StartupType "Manual" -ErrorAction Stop
        Start-Service -Name "lfsvc" -ErrorAction Stop
        Write-StatusMessage -Message "Geolocation service enabled and started" -Type Success
        Write-StatusMessage -Message "Location services are now available" -Type Warning
    } else {
        # Disable the service and stop it
        Stop-Service -Name "lfsvc" -ErrorAction Stop
        Set-Service -Name "lfsvc" -StartupType "Disabled" -ErrorAction Stop
        Write-StatusMessage -Message "Geolocation service stopped and disabled" -Type Success
        Write-StatusMessage -Message "Location services are now disabled" -Type Warning
    }
    
    # Verify the new startup type
    Start-Sleep -Seconds 2
    $newService = Get-Service -Name "lfsvc"
    Write-StatusMessage -Message "New Geolocation service startup type: $($newService.StartType)" -Type Info
    Write-StatusMessage -Message "Current service status: $($newService.Status)" -Type Info
    
    Write-StatusMessage -Message "Note: Startup type changes require a reboot to take full effect" -Type Warning
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Geolocation service startup type: $($_.Exception.Message)"
}