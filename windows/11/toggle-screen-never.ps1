# Toggle screen off behavior on both battery and plugged in for Windows 11

try {
    # Get current power scheme
    $powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'
    
    # Query current display settings using reliable method
    $displaySettings = powercfg -q $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
    
    # Parse current values - look for both decimal and hex formats
    $dcSetting = $displaySettings | Select-String "Current DC Power Setting Index.*0x(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    $acSetting = $displaySettings | Select-String "Current AC Power Setting Index.*0x(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    # Convert hex to decimal
    $currentDC = if ($dcSetting) { [Convert]::ToInt32($dcSetting, 16) } else { 300 }
    $currentAC = if ($acSetting) { [Convert]::ToInt32($acSetting, 16) } else { 300 }
    
    Write-Host "Current DC: $currentDC seconds, Current AC: $currentAC seconds" -ForegroundColor Gray
    
    # Toggle logic - if current is not 0, set to 0 (never), else set to 300 (5 mins)
    $newDCValue = if ($currentDC -ne 0) { 0 } else { 300 }
    $newACValue = if ($currentAC -ne 0) { 0 } else { 300 }
    
    # Set new values using power scheme
    powercfg -setdcvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newDCValue
    powercfg -setacvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newACValue
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    if ($newDCValue -eq 0) {
        Write-Host "✅ Screen off disabled for both battery and plugged in power" -ForegroundColor Green
        Write-Host "DC (battery): Never turn off | AC (plugged in): Never turn off" -ForegroundColor Cyan
    } else {
        Write-Host "✅ Screen off re-enabled (5 minutes timeout)" -ForegroundColor Yellow
        Write-Host "DC (battery): 5 minutes | AC (plugged in): 5 minutes" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Failed to toggle screen timeout settings: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}