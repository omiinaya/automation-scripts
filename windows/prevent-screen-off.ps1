# Prevent screen from turning off on both battery and plugged in for Windows 11
$powerScheme = (powercfg -getactivescheme) -replace '.*: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12}).*', '$1'

try {
    # Set display timeout to "never" (0) for both battery and AC power
    powercfg -setdcvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
    powercfg -setacvalueindex $powerScheme 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
    
    # Apply the changes
    powercfg -setactive $powerScheme
    
    Write-Host "✅ Screen off disabled for both battery and plugged in power" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to disable screen timeout: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}