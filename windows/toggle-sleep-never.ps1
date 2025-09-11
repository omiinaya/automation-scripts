# Toggle sleep behavior on both battery and plugged in for Windows 11
$powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'

try {
    # Query current sleep settings
    $sleepSettings = powercfg -q $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da
    
    # Extract current values using simpler parsing
    $dcLine = $sleepSettings | Select-String "DC.*Index.*0x" | Select-Object -First 1
    $acLine = $sleepSettings | Select-String "AC.*Index.*0x" | Select-Object -First 1
    
    $currentDC = if ($dcLine) { [int]($dcLine -replace '.*Index.*0x(\w+).*', '$1') } else { 900 }
    $currentAC = if ($acLine) { [int]($acLine -replace '.*Index.*0x(\w+).*', '$1') } else { 900 }
    
    # Toggle logic - if current is not 0, set to 0 (never), else set to 900 (15 mins)
    $newDCValue = if ($currentDC -ne 0) { 0 } else { 900 }
    $newACValue = if ($currentAC -ne 0) { 0 } else { 900 }
    
    # Set new values
    powercfg -setdcvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da $newDCValue
    powercfg -setacvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da $newACValue
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    if ($newDCValue -eq 0) {
        Write-Host "✅ Sleep disabled for both battery and plugged in power" -ForegroundColor Green
    } else {
        Write-Host "✅ Sleep re-enabled (15 minutes timeout)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Failed to toggle sleep settings: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}