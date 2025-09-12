# Set power mode to "Best Performance" on Windows 11
# Refactored to use modular system - reduces from 13 lines to 5 lines

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
    # Check admin rights and set high performance
    if (Test-AdminRights) {
        Set-PowerScheme -SchemeGUID "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        Write-StatusMessage -Message "Power mode set to 'Best Performance' - maximum performance at higher power consumption" -Type Success
    } else {
        Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
        Request-Elevation
    }
} catch {
    Wait-OnError -ErrorMessage "Failed to set high performance mode: $($_.Exception.Message)"
}