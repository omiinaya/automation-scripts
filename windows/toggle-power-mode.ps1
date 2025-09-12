# Toggle between Recommended (Balanced) and Best Performance (High Performance) power modes
# Refactored to use modular system for Windows 11

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

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-StatusMessage -Message "Administrator privileges required to modify power schemes" -Type Error
    Request-Elevation
    exit
}

try {
    # Get all available power schemes
    $schemes = Get-PowerSchemes
    
    # Find the schemes we need
    $balancedScheme = $schemes | Where-Object { $_.Name -like "*Balanced*" -or $_.Name -like "*Recommended*" } | Select-Object -First 1
    $highPerformanceScheme = $schemes | Where-Object { $_.Name -like "*High performance*" -or $_.Name -like "*Best performance*" } | Select-Object -First 1
    
    if (-not $balancedScheme -or -not $highPerformanceScheme) {
        Write-Host "Available power schemes:" -ForegroundColor Yellow
        $schemes | Format-Table -AutoSize | Out-Host
        throw "Unable to find required power schemes. Please ensure both 'Balanced' and 'High performance' schemes are available."
    }
    
    # Get current active scheme
    $currentScheme = Get-ActivePowerScheme
    
    Write-Host "`nCurrent power mode: " -NoNewline
    Write-Host $currentScheme.Name -ForegroundColor Cyan
    
    # Determine which scheme to switch to
    if ($currentScheme.GUID -eq $highPerformanceScheme.GUID) {
        # Currently on high performance, switch to balanced
        $targetScheme = $balancedScheme
        $targetName = "Recommended (Balanced)"
    } else {
        # Currently on balanced or other, switch to high performance
        $targetScheme = $highPerformanceScheme
        $targetName = "Best Performance (High Performance)"
    }
    
    Write-Host "`nSwitching to: " -NoNewline 
    Write-Host $targetName -ForegroundColor Green
    
    # Set the new power scheme
    Set-PowerScheme -SchemeGUID $targetScheme.GUID
    
    # Verify the change
    $newScheme = Get-ActivePowerScheme
    if ($newScheme.GUID -eq $targetScheme.GUID) {
        Write-StatusMessage -Message "Power mode successfully changed to: $($newScheme.Name)" -Type Success
    } else {
        Write-StatusMessage -Message "Power mode change may not have been applied correctly" -Type Warning
    }
    
    # Show power scheme information
    Write-Host "`nPower Scheme Details:" -ForegroundColor Yellow
    Write-Host "GUID: $($newScheme.GUID)" -ForegroundColor Gray
    Write-Host "Active: $($newScheme.Active)" -ForegroundColor Gray
    
    # Optionally show battery info if available
    $batteryInfo = Get-BatteryInfo
    if ($batteryInfo) {
        Write-Host "`nBattery Information:" -ForegroundColor Yellow
        Write-Host "Charge Level: $($batteryInfo.ChargeLevel)%"
        Write-Host "Status: $($batteryInfo.Status)"
        if ($batteryInfo.EstimatedRuntime -gt 0) {
            Write-Host "Estimated Runtime: $($batteryInfo.EstimatedRuntime) minutes"
        }
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle power mode: $($_.Exception.Message)"
}