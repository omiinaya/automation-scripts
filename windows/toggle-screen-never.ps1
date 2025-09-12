# Toggle screen off behavior on both battery and plugged in for Windows 11
# Refactored to use modular system - reduces from 42 lines to 20 lines

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "modules\ModuleIndex.psm1"
Import-Module $modulePath -Force

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
    Request-Elevation
    exit
}

try {
    $powerScheme = (Get-ActivePowerScheme).GUID
    
    # Query current display settings
    $displaySettings = powercfg -q $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
    
    # Parse current values
    $dcSetting = $displaySettings | Select-String "Current DC Power Setting Index.*0x(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    $acSetting = $displaySettings | Select-String "Current AC Power Setting Index.*0x(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    $currentDC = if ($dcSetting) { [Convert]::ToInt32($dcSetting, 16) } else { 300 }
    $currentAC = if ($acSetting) { [Convert]::ToInt32($acSetting, 16) } else { 300 }
    
    # Toggle logic
    $newDCValue = if ($currentDC -ne 0) { 0 } else { 300 }
    $newACValue = if ($currentAC -ne 0) { 0 } else { 300 }
    
    # Apply changes
    powercfg -setdcvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newDCValue
    powercfg -setacvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newACValue
    Set-PowerScheme -SchemeGUID $powerScheme
    
    if ($newDCValue -eq 0) {
        Write-StatusMessage -Message "Screen off disabled for both battery and plugged in power" -Type Success
        Write-StatusMessage -Message "DC (battery): Never turn off | AC (plugged in): Never turn off" -Type Info
    } else {
        Write-StatusMessage -Message "Screen off re-enabled (5 minutes timeout)" -Type Success
        Write-StatusMessage -Message "DC (battery): 5 minutes | AC (plugged in): 5 minutes" -Type Info
    }
    
} catch {
    Write-StatusMessage -Message "Failed to toggle screen timeout settings: $($_.Exception.Message)" -Type Error
    Write-StatusMessage -Message "This script requires administrator privileges to modify power settings." -Type Warning
}