# Toggle Print Spooler service on Windows
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
    
    # Determine action based on current state
    if ($service.Status -eq "Running") {
        # Stop the service
        Stop-Service -Name "Spooler" -Force -ErrorAction Stop
        Write-StatusMessage -Message "Print Spooler service stopped" -Type Success
        Write-StatusMessage -Message "Printing functionality will be disabled" -Type Warning
    } else {
        # Start the service
        Start-Service -Name "Spooler" -ErrorAction Stop
        Write-StatusMessage -Message "Print Spooler service started" -Type Success
        Write-StatusMessage -Message "Printing functionality is now available" -Type Info
    }
    
    # Verify the new status
    Start-Sleep -Seconds 2
    $newService = Get-Service -Name "Spooler"
    Write-StatusMessage -Message "New Print Spooler status: $($newService.Status)" -Type Info
    
    Write-StatusMessage -Message "Note: Service changes take effect immediately" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle Print Spooler service: $($_.Exception.Message)"
}