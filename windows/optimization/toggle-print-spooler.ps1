# Toggle Print Spooler service startup type on Windows
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
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Host "`nWARNING: This operation may require administrator privileges" -ForegroundColor Yellow
        Write-Host "Some service operations may fail without elevated permissions" -ForegroundColor Yellow
    }
    
    # Get current service status
    $service = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
    
    if (-not $service) {
        throw "Print Spooler service (Spooler) not found on this system"
    }
    
    Write-StatusMessage -Message "Current Print Spooler status: $($service.Status)" -Type Info
    Write-StatusMessage -Message "Current startup type: $($service.StartType)" -Type Info
    
    # Determine action based on current startup type
    if ($service.StartType -eq "Disabled") {
        # Enable the service (set to Automatic) and start it
        Set-Service -Name "Spooler" -StartupType "Automatic" -ErrorAction Stop
        Start-Service -Name "Spooler" -ErrorAction Stop
        Write-StatusMessage -Message "Print Spooler service enabled and started" -Type Success
        Write-StatusMessage -Message "Printing functionality is now available" -Type Warning
    } else {
        # Disable the service and stop it
        Stop-Service -Name "Spooler" -ErrorAction Stop
        Set-Service -Name "Spooler" -StartupType "Disabled" -ErrorAction Stop
        Write-StatusMessage -Message "Print Spooler service stopped and disabled" -Type Success
        Write-StatusMessage -Message "Printing functionality is now disabled" -Type Warning
    }
    
    # Verify the new startup type
    Start-Sleep -Seconds 2
    $newService = Get-Service -Name "Spooler"
    Write-StatusMessage -Message "New Print Spooler startup type: $($newService.StartType)" -Type Info
    Write-StatusMessage -Message "Current service status: $($newService.Status)" -Type Info
    
    Write-StatusMessage -Message "Note: Startup type changes require a reboot to take full effect" -Type Warning
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Print Spooler service startup type: $($_.Exception.Message)"
}