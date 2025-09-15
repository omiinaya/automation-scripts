# Check CPU Core Parking Status on Windows
# Verifies current core parking configuration across all power schemes

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
try {
    Import-Module $modulePath -Force -ErrorAction Stop
} catch {
    Write-Host "Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    Wait-OnError -ErrorMessage "Module import failed"
    exit
}

# Check admin rights - always require for proper functionality
if (-not (Test-AdminRights)) {
    Write-StatusMessage -Message "Administrator privileges required to read CPU core parking settings" -Type Error
    
    # Store that we need to pause after elevation
    $script:ShouldPause = $true
    Request-Elevation
    exit
}

# Initialize pause flag
$script:ShouldPause = $false

try {
    Write-SectionHeader -Title "CPU Core Parking Status Check"
    
    # Get system information
    $processorInfo = Get-SystemInfo
    $coreCount = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    $logicalProcessors = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    
    Write-StatusMessage -Message "System Information:" -Type Info
    Write-Host "  Processor: $($processorInfo.CPUName)" -ForegroundColor Cyan
    Write-Host "  Physical Cores: $coreCount" -ForegroundColor Cyan
    Write-Host "  Logical Processors: $logicalProcessors" -ForegroundColor Cyan
    Write-Host ""
    
    # Get active power scheme
    $activeScheme = Get-ActivePowerScheme
    Write-StatusMessage -Message "Active Power Scheme: $($activeScheme.Name)" -Type Info
    Write-Host ""
    
    # Check processor power management settings (available on this system)
    $powerSchemes = Get-PowerSchemes
    $cpuSubgroupGuid = "54533251-82be-4824-96c1-47b60b740d00"  # Processor power management
    $minProcessorStateGuid = "893dee8e-2bef-41e0-89c6-b55d0929964c"  # Minimum processor state
    $maxProcessorStateGuid = "bc5038f7-23e0-4960-96da-33abaf5935ec"  # Maximum processor state
    
    Write-StatusMessage -Message "Checking Processor Power Management Settings:" -Type Info
    Write-Host "Note: CPU core parking settings not available on this system" -ForegroundColor Yellow
    Write-Host "Showing minimum/maximum processor state instead:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($scheme in $powerSchemes) {
        try {
            $schemeGuid = $scheme.GUID
            $isActive = ($schemeGuid -eq $activeScheme.GUID)
            
            # Get minimum processor state
            $minResult = powercfg -q $schemeGuid $cpuSubgroupGuid $minProcessorStateGuid 2>&1
            $minAc = $minResult | Select-String "Current AC Power Setting Index.*0x([0-9a-f]+)"
            $minDc = $minResult | Select-String "Current DC Power Setting Index.*0x([0-9a-f]+)"
            
            # Get maximum processor state  
            $maxResult = powercfg -q $schemeGuid $cpuSubgroupGuid $maxProcessorStateGuid 2>&1
            $maxAc = $maxResult | Select-String "Current AC Power Setting Index.*0x([0-9a-f]+)"
            $maxDc = $maxResult | Select-String "Current DC Power Setting Index.*0x([0-9a-f]+)"
            
            $minAcValue = if ($minAc) { [convert]::ToInt32($minAc.Matches.Groups[1].Value, 16) } else { "ERR" }
            $minDcValue = if ($minDc) { [convert]::ToInt32($minDc.Matches.Groups[1].Value, 16) } else { "ERR" }
            $maxAcValue = if ($maxAc) { [convert]::ToInt32($maxAc.Matches.Groups[1].Value, 16) } else { "ERR" }
            $maxDcValue = if ($maxDc) { [convert]::ToInt32($maxDc.Matches.Groups[1].Value, 16) } else { "ERR" }
            
            if ($isActive) {
                Write-Host "[ACTIVE] " -NoNewline -ForegroundColor Yellow
            } else {
                Write-Host "         " -NoNewline
            }
            
            Write-Host "$($scheme.Name.PadRight(30)) " -NoNewline
            Write-Host "Min: $($minAcValue.ToString().PadLeft(2))/$($minDcValue.ToString().PadLeft(2)) " -NoNewline -ForegroundColor Cyan
            Write-Host "Max: $($maxAcValue.ToString().PadLeft(2))/$($maxDcValue.ToString().PadLeft(2))" -ForegroundColor Cyan
            
        } catch {
            Write-Host "         $($scheme.Name) - Error reading settings" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-StatusMessage -Message "Legend:" -Type Info
    Write-Host "  Min: AC/DC Minimum Processor State (%)" -ForegroundColor Cyan
    Write-Host "  Max: AC/DC Maximum Processor State (%)" -ForegroundColor Cyan
    Write-Host "  Values show AC/DC power settings" -ForegroundColor Cyan
    Write-Host ""
    Write-StatusMessage -Message "Note: CPU core parking settings not available on this system" -Type Warning
    Write-StatusMessage -Message "Showing minimum/maximum processor state instead for comparison" -Type Info
    
    # Check additional registry settings
    Write-StatusMessage -Message "Checking Additional Registry Settings:" -Type Info
    
    $registryPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power",
        "HKLM:\SYSTEM\CurrentControlSet\Services\intelppm",
        "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm"
    )
    
    foreach ($path in $registryPaths) {
        if (Test-Path -Path $path) {
            try {
                $pathName = Split-Path $path -Leaf
                Write-Host ("  {0}: " -f $pathName) -NoNewline -ForegroundColor Cyan
                
                if ($path -like "*intelppm*" -or $path -like "*amdppm*") {
                    $startValue = Get-ItemProperty -Path $path -Name "Start" -ErrorAction SilentlyContinue
                    if ($startValue) {
                        $status = if ($startValue.Start -eq 4) { "DISABLED" } else { "ENABLED" }
                        Write-Host $status -ForegroundColor (if ($startValue.Start -eq 4) { "Green" } else { "Red" })
                    } else {
                        Write-Host "DEFAULT" -ForegroundColor Yellow
                    }
                } else {
                    $coalescingValue = Get-ItemProperty -Path $path -Name "CoalescingTimerInterval" -ErrorAction SilentlyContinue
                    if ($coalescingValue) {
                        $status = if ($coalescingValue.CoalescingTimerInterval -eq 0) { "DISABLED" } else { "ENABLED" }
                        Write-Host $status -ForegroundColor (if ($coalescingValue.CoalescingTimerInterval -eq 0) { "Green" } else { "Red" })
                    } else {
                        Write-Host "DEFAULT" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "ERROR" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-StatusMessage -Message "Summary:" -Type Info
    Write-Host "  Run this script BEFORE and AFTER using unpark-cores.ps1" -ForegroundColor Yellow
    Write-Host "  Compare the values to verify core parking changes" -ForegroundColor Yellow
    Write-Host "  Lower minimum values may indicate more aggressive power saving" -ForegroundColor Yellow
    Write-Host "  Lower maximum values limit CPU performance" -ForegroundColor Yellow
    Write-Host ""
    
    # Pause to see results if we're in an elevated session or originally requested pause
    if ($script:ShouldPause -or (Test-AdminRights)) {
        Write-Host ""
        Write-Host "Press Enter to close..." -ForegroundColor Yellow
        $null = Read-Host
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to check CPU core parking status: $($_.Exception.Message)"
}