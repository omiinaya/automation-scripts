# DEPRECATED: This script is deprecated. Use toggle-lid-close.ps1 instead.
# Set "When closing the lid" to "do nothing" on both battery and plugged in for Windows 11
# Note: toggle-lid-close.ps1 provides toggle functionality between "Do nothing" and "Sleep"

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
    # Check admin rights and set lid close action
    Write-Host "`nWARNING: This script is deprecated!" -ForegroundColor Red
    Write-Host "Please use 'toggle-lid-close.ps1' instead for toggle functionality." -ForegroundColor Yellow
    Write-Host "It provides switching between 'Do nothing' and 'Sleep' modes." -ForegroundColor Cyan
    Write-Host "`nPress Enter to close..." -ForegroundColor Gray
    Read-Host
    exit
    
    # Original functionality (kept for reference):
    # if (Test-AdminRights) {
    #     $powerScheme = (Get-ActivePowerScheme).GUID
    #     powercfg -setdcvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    #     powercfg -setacvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    #     Set-PowerScheme -SchemeGUID $powerScheme
    #     Write-StatusMessage -Message "Lid close behavior set to 'Do nothing' for both battery and plugged in power" -Type Success
    # } else {
    #     Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
    #     Request-Elevation
    # }
} catch {
    Wait-OnError -ErrorMessage "Failed to set lid close behavior: $($_.Exception.Message)"
}