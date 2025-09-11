# Toggle screen off behavior on both battery and plugged in for Windows 11
$powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'

try {
    # Query current display settings
    $displaySettings = powercfg -q $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
    
    # Extract current values using simpler parsing
    $dcLine = $displaySettings | Select-String "DC.*Index.*0x" | Select-Object -First 1
    $acLine = $displaySettings | Select-String "AC.*Index.*0x" | Select-Object -First 1
    
    $currentDC = if ($dcLine) { [int]($dcLine -replace '.*Index.*0x(\w+).*', '$1') } else { 300 }
    $currentAC = if ($acLine) { [int]($acLine -replace '.*Index.*0x(\w+).*', '$1') } else { 300 }
    
    # Toggle logic - if current is not 0, set to 0 (never), else set to 300 (5 mins)
    $newDCValue = if ($currentDC -ne 0) { 0 } else { 300 }
    $newACValue = if ($currentAC -ne 0) { 0 } else { 300 }
    
    # Set new values
    powercfg -setdcvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newDCValue
    powercfg -setacvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e $newACValue
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    if ($newDCValue -eq 0) {
        Write-Host "✅ Screen off disabled for both battery and plugged in power" -ForegroundColor Green
    } else {
        Write-Host "✅ Screen off re-enabled (5 minutes timeout)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Failed to toggle screen timeout settings: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}