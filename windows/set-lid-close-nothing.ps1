# Set "When closing the lid" to "do nothing" on both battery and plugged in for Windows 11
# Refactored to use modular system - reduces from 17 lines to 8 lines

# Import the Windows modules
Import-Module .\windows\modules\ModuleIndex.psm1 -Force

# Check admin rights and set lid close action
if (Test-AdminRights) {
    $powerScheme = (Get-ActivePowerScheme).GUID
    powercfg -setdcvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    powercfg -setacvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    Set-PowerScheme -SchemeGUID $powerScheme
    Write-StatusMessage -Message "Lid close behavior set to 'Do nothing' for both battery and plugged in power" -Type Success
} else {
    Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
    Request-Elevation
}