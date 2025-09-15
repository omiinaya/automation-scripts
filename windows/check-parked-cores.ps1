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
    Request-Elevation
    exit
}

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
    
    # Check core parking settings for all power schemes
    $powerSchemes = Get-PowerSchemes
    $cpuParkingGuid = "0cc5b647-c1df-4637-891a-dec35c318583"
    $cpuSubgroupGuid = "54533251-82be-4824-96c1-47b60b740d00"
    
    Write-StatusMessage -Message "Checking Core Parking Settings:" -Type Info
    
    foreach ($scheme in $powerSchemes) {
        try {
            $schemeGuid = $scheme.GUID
            $isActive = ($schemeGuid -eq $activeScheme.GUID)
            
            # Get power settings with better error handling
            try {
                $powerResult = powercfg -q $schemeGuid $cpuSubgroupGuid $cpuParkingGuid 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "powercfg failed with exit code $LASTEXITCODE"
                }
                
                $acParking = $powerResult | Select-String "Current AC Power Setting Index.*0x([0-9a-f]+)"
                $dcParking = $powerResult | Select-String "Current DC Power Setting Index.*0x([0-9a-f]+)"
                
                $acValue = if ($acParking) { [convert]::ToInt32($acParking.Matches.Groups[1].Value, 16) } else { "ERR" }
                $dcValue = if ($dcParking) { [convert]::ToInt32($dcParking.Matches.Groups[1].Value, 16) } else { "ERR" }
            } catch {
                $acValue = "ERR"
                $dcValue = "ERR"
            }
            
            if ($acValue -eq "ERR" -or $dcValue -eq "ERR") {
                $statusSymbol = "[?]"
                $statusText = "ERROR"
                $statusColor = "Yellow"
            } elseif ($acValue -eq 0 -and $dcValue -eq 0) {
                $statusSymbol = "[X]"
                $statusText = "DISABLED"
                $statusColor = "Green"
            } else {
                $statusSymbol = "[V]"
                $statusText = "ENABLED"
                $statusColor = "Red"
            }
            
            if ($isActive) {
                Write-Host "[ACTIVE] " -NoNewline -ForegroundColor Yellow
            } else {
                Write-Host "         " -NoNewline
            }
            
            Write-Host "$statusSymbol $($scheme.Name.PadRight(30)) " -NoNewline
            Write-Host "AC: $($acValue.ToString().PadLeft(3)) " -NoNewline -ForegroundColor Cyan
            Write-Host "DC: $($dcValue.ToString().PadLeft(3)) " -NoNewline -ForegroundColor Cyan
            Write-Host "[$statusText]" -ForegroundColor $statusColor
            
        } catch {
            Write-Host "         $($scheme.Name) - Error reading settings" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-StatusMessage -Message "Legend:" -Type Info
    Write-Host "  [X] = Core Parking DISABLED (0 = unparked)" -ForegroundColor Green
    Write-Host "  [V] = Core Parking ENABLED (100 = parked)" -ForegroundColor Red
    Write-Host "  [?] = Error reading setting" -ForegroundColor Yellow
    Write-Host "  AC = AC Power (plugged in)" -ForegroundColor Cyan
    Write-Host "  DC = DC Power (battery)" -ForegroundColor Cyan
    
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
    Write-Host "  Values of '0' indicate core parking is DISABLED" -ForegroundColor Green
    Write-Host "  Values of '100' indicate core parking is ENABLED" -ForegroundColor Red
    Write-Host ""
    
    # Pause to see results
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    Read-Host
    
} catch {
    Wait-OnError -ErrorMessage "Failed to check CPU core parking status: $($_.Exception.Message)"
}