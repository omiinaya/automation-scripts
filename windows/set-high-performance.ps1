# Set power mode to "Best Performance" on Windows 11

try {
    # Set power scheme to "Best Performance" (high performance)
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    Write-Host "✅ Power mode set to 'Best Performance'" -ForegroundColor Green
    Write-Host "Note: This enables maximum system performance at the cost of higher power consumption" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Failed to set power mode to Best Performance: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires administrator privileges to modify power settings." -ForegroundColor Yellow
}