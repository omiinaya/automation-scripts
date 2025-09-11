# Set "When closing the lid" to "do nothing" on both battery and plugged in for Windows 11
$powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'

try {
    # Set lid close action to "do nothing" (0) for both battery and AC power
    powercfg -setdcvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    powercfg -setacvalueindex $powerScheme 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    Write-Host "✅ Lid close behavior set to 'Do nothing' for both battery and plugged in" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to set lid close behavior: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}