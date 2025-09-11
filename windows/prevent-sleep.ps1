# Prevent computer from going to sleep on both battery and plugged in for Windows 11
$powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'

try {
    # Set sleep timeout to "never" (0) for both battery and AC power
    powercfg -setdcvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0
    powercfg -setacvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    Write-Host "✅ Sleep disabled for both battery and plugged in power" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to disable sleep: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}