# Unpark all CPU cores on Windows 11
# Optimizes CPU performance by disabling core parking across all processors

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
    Write-StatusMessage -Message "Administrator privileges required to modify CPU core parking settings" -Type Error
    Request-Elevation
    exit
}

try {
    Write-SectionHeader -Title "CPU Core Unparking Tool"
    
    # Get system information
    $processorInfo = Get-SystemInfo
    $coreCount = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    $logicalProcessors = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    
    Write-StatusMessage -Message "Detected $coreCount physical cores ($logicalProcessors logical processors)" -Type Info
    
    # Registry paths for CPU core parking
    $cpuRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    $cpuParkedPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583\DefaultPowerSchemeValues"
    
    # Backup current settings
    $backupPath = Join-Path $env:TEMP "cpu-parking-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"
    Write-StatusMessage -Message "Creating backup of current settings..." -Type Info
    
    try {
        $powerScheme = (Get-ActivePowerScheme).GUID
        $backupCommand = "reg export `"$cpuRegistryPath`" `"$backupPath`" /y"
        Invoke-Expression $backupCommand | Out-Null
        Write-StatusMessage -Message "Backup saved to: $backupPath" -Type Success
    } catch {
        Write-StatusMessage -Message "Could not create registry backup: $($_.Exception.Message)" -Type Warning
    }
    
    # Disable core parking for all power schemes
    Write-StatusMessage -Message "Disabling CPU core parking across all power schemes..." -Type Info
    
    # Get all power schemes
    $powerSchemes = Get-PowerSchemes
    
    foreach ($scheme in $powerSchemes) {
        try {
            # Set minimum processor state to 100% (disables core parking)
            $schemeGuid = $scheme.GUID
            
            # Set for both AC and DC power
            powercfg -setacvalueindex $schemeGuid 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 | Out-Null
            powercfg -setdcvalueindex $schemeGuid 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 | Out-Null
            
            Write-StatusMessage -Message "Updated scheme: $($scheme.Name)" -Type Success
        } catch {
            Write-StatusMessage -Message "Failed to update scheme: $($scheme.Name) - $($_.Exception.Message)" -Type Warning
        }
    }
    
    # Apply changes to current scheme
    Set-PowerScheme -SchemeGUID (Get-ActivePowerScheme).GUID
    
    # Additional registry modifications for thorough core unparking
    $additionalPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power",
        "HKLM:\SYSTEM\CurrentControlSet\Services\intelppm",
        "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm"
    )
    
    foreach ($path in $additionalPaths) {
        if (Test-Path -Path $path) {
            try {
                if ($path -like "*intelppm*" -or $path -like "*amdppm*") {
                    # Disable processor power management services
                    Set-RegistryValue -KeyPath $path -ValueName "Start" -ValueData 4 -ValueType DWord
                } else {
                    # Set power throttling settings
                    Set-RegistryValue -KeyPath $path -ValueName "CoalescingTimerInterval" -ValueData 0 -ValueType DWord
                }
            } catch {
                Write-StatusMessage -Message "Could not modify: $path" -Type Warning
            }
        }
    }
    
    # Verify the changes
    Write-StatusMessage -Message "Verifying core parking settings..." -Type Info
    
    $verification = powercfg -q (Get-ActivePowerScheme).GUID 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583
    $parkingSetting = $verification | Select-String "Current AC Power Setting Index.*0x00000000"
    
    if ($parkingSetting) {
        Write-StatusMessage -Message "SUCCESS: CPU core parking has been disabled!" -Type Success
        Write-StatusMessage -Message "All CPU cores are now unparked and available for maximum performance" -Type Info
    } else {
        Write-StatusMessage -Message "WARNING: Core parking settings may not have been applied correctly" -Type Warning
    }
    
    # Display system information
    Write-Host ""
    Write-StatusMessage -Message "System Information:" -Type Info
    Write-Host "  Processor: $($processorInfo.CPUName)" -ForegroundColor Cyan
    Write-Host "  Cores: $coreCount" -ForegroundColor Cyan
    Write-Host "  Logical Processors: $logicalProcessors" -ForegroundColor Cyan
    Write-Host ""
    Write-StatusMessage -Message "Changes take effect immediately. Restart your computer for complete optimization." -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to unpark CPU cores: $($_.Exception.Message)"
}