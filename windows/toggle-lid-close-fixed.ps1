# Toggle lid close behavior between "Do nothing" and "Sleep" for Windows 11
# Updated version with GUID validation and discovery capabilities

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Function to convert hex string to integer
function Convert-HexStringToInt {
    param([string]$HexString)
    try {
        return [Convert]::ToInt32($HexString, 16)
    } catch {
        return $null
    }
}

# Function to discover correct GUIDs
function Find-CorrectLidCloseGuids {
    Write-Host "`n=== GUID DISCOVERY ===" -ForegroundColor Yellow
    
    # Known standard GUIDs for Windows 10/11
    $standardGuids = @{
        SubgroupName = "Power buttons and lid"
        SubgroupGuid = "4f971e89-eebd-4455-a8de-9e59040e7347"
        SettingName = "Lid close action"
        SettingGuid = "5ca83367-6e45-459f-a27b-476b1d01c936"
    }
    
    # Alternative GUIDs found in some systems
    $alternativeGuids = @(
        @{
            SubgroupName = "System settings"
            SubgroupGuid = "238C9FA8-0AAD-41ED-83F4-97BE242C8F20"
            SettingName = "Lid close action"
            SettingGuid = "5ca83367-6e45-459f-a27b-476b1d01c936"
        }
    )
    
    # Test standard GUIDs first
    Write-Host "Testing standard GUIDs..." -ForegroundColor Gray
    $testResults = @()
    
    foreach ($guidSet in @($standardGuids) + $alternativeGuids) {
        try {
            $scheme = (powercfg /getactivescheme) -match "([0-9a-fA-F\-]{36})" | % { $matches[1] }
            $result = powercfg /query $scheme $guidSet.SubgroupGuid $guidSet.SettingGuid 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Found valid GUID combination: $($guidSet.SubgroupName) -> $($guidSet.SettingName)" -ForegroundColor Green
                $testResults += $guidSet
            } else {
                Write-Host "  ✗ Invalid: $($guidSet.SubgroupGuid) + $($guidSet.SettingGuid)" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "  ✗ Error testing: $_" -ForegroundColor DarkGray
        }
    }
    
    if ($testResults.Count -eq 0) {
        Write-Host "No standard GUIDs found. Running comprehensive discovery..." -ForegroundColor Yellow
        
        # Comprehensive discovery - query all subgroups and look for lid-related settings
        $scheme = (powercfg /getactivescheme) -match "([0-9a-fA-F\-]{36})" | % { $matches[1] }
        $allSettings = powercfg /query $scheme
        
        $lidPatterns = @("lid", "close", "cover")
        $foundGuids = @()
        
        foreach ($line in $allSettings) {
            if ($line -match "SUBGROUP\s+([0-9a-fA-F\-]{36})\s+\(([^)]+)\)") {
                $subgroupGuid = $matches[1]
                $subgroupName = $matches[2]
                
                # Check if this subgroup contains lid-related settings
                $subgroupSettings = powercfg /query $scheme $subgroupGuid
                foreach ($settingLine in $subgroupSettings) {
                    if ($settingLine -match "POWER\s+SETTING\s+([0-9a-fA-F\-]{36})\s+\(([^)]*lid[^)]*)\)") {
                        $settingGuid = $matches[1]
                        $settingName = $matches[2]
                        
                        $foundGuids += @{
                            SubgroupName = $subgroupName
                            SubgroupGuid = $subgroupGuid
                            SettingName = $settingName
                            SettingGuid = $settingGuid
                        }
                    }
                }
            }
        }
        
        if ($foundGuids.Count -gt 0) {
            Write-Host "Found lid-related settings:" -ForegroundColor Green
            foreach ($guid in $foundGuids) {
                Write-Host "  Subgroup: $($guid.SubgroupName) ($($guid.SubgroupGuid))" -ForegroundColor Cyan
                Write-Host "  Setting: $($guid.SettingName) ($($guid.SettingGuid))" -ForegroundColor Cyan
            }
            return $foundGuids[0]
        }
    } elseif ($testResults.Count -eq 1) {
        return $testResults[0]
    } else {
        Write-Host "Multiple valid combinations found, using first one" -ForegroundColor Yellow
        return $testResults[0]
    }
    
    # Fallback to manual input
    Write-Host "Could not automatically discover GUIDs. Please run debug-lid-close-guids.ps1 for detailed discovery." -ForegroundColor Red
    return $null
}

# Function to validate and get GUIDs with fallback
function Get-ValidatedLidCloseGuids {
    param(
        [switch]$AutoDiscover
    )
    
    # Try to load from working file
    $workingFile = "working-lid-close-guids.json"
    if (Test-Path $workingFile) {
        Write-Host "Loading GUIDs from working file..." -ForegroundColor Green
        return Get-Content $workingFile | ConvertFrom-Json
    }
    
    # Auto-discover if requested
    if ($AutoDiscover) {
        $discovered = Find-CorrectLidCloseGuids
        if ($discovered) {
            # Save for future use
            $discovered | ConvertTo-Json | Out-File $workingFile -Encoding UTF8
            Write-Host "Saved discovered GUIDs to $workingFile" -ForegroundColor Green
            return $discovered
        }
    }
    
    # Use standard GUIDs with warning
    Write-Host "Using standard Windows 10/11 GUIDs. If these fail, run with -AutoDiscover flag." -ForegroundColor Yellow
    return @{
        SubgroupName = "Power buttons and lid"
        SubgroupGuid = "4f971e89-eebd-4455-a8de-9e59040e7347"
        SettingName = "Lid close action"
        SettingGuid = "5ca83367-6e45-459f-a27b-476b1d01c936"
    }
}

# Import the Windows modules
try {
    $modulePath = Join-Path $PSScriptRoot "modules\ModuleIndex.psm1"
    Import-Module $modulePath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Warning: Could not load Windows modules. Using fallback methods." -ForegroundColor Yellow
}

# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required to modify power settings" -ForegroundColor Red
    
    # Try to request elevation
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -AutoDiscover"
    $psi.Verb = "runas"
    
    try {
        [System.Diagnostics.Process]::Start($psi)
        exit
    } catch {
        Write-Host "Failed to elevate privileges. Please run as Administrator." -ForegroundColor Red
        exit 1
    }
}

try {
    # Get validated GUIDs
    $guids = Get-ValidatedLidCloseGuids -AutoDiscover
    
    if (-not $guids) {
        throw "Failed to determine correct GUIDs for lid close settings"
    }
    
    $powerScheme = (powercfg /getactivescheme) -match "([0-9a-fA-F\-]{36})" | % { $matches[1] }
    $lidCloseGUID = $guids.SettingGuid
    $powerSettingSubgroup = $guids.SubgroupGuid
    
    Write-Host "=== LID CLOSE TOGGLE ===" -ForegroundColor Cyan
    Write-Host "Active Power Scheme: $powerScheme" -ForegroundColor Gray
    Write-Host "Using GUIDs: $powerSettingSubgroup + $lidCloseGUID" -ForegroundColor Gray
    
    # Get current lid close settings
    $lidSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    $currentDC = $null
    $currentAC = $null
    
    foreach ($line in $lidSettings) {
        if ($line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
            $currentDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
            $currentAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    if ($null -eq $currentDC -or $null -eq $currentAC) {
        Write-Host "Raw powercfg output:" -ForegroundColor Gray
        $lidSettings | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        throw "Failed to parse current lid close settings. This may indicate incorrect GUIDs."
    }
    
    Write-Host "`nCurrent lid close settings:" -ForegroundColor Cyan
    Write-Host "  DC (Battery): $currentDC" -ForegroundColor White
    Write-Host "  AC (Plugged in): $currentAC" -ForegroundColor White
    
    # Ensure both AC and DC values are consistent
    if ($currentDC -ne $currentAC) {
        Write-Host "Warning: Inconsistent AC/DC settings detected. Syncing both to the same value..." -ForegroundColor Yellow
    }
    
    # Use the AC value as the reference for consistency
    $referenceValue = $currentAC
    
    # Toggle logic: 0 = Do nothing, 1 = Sleep, 2 = Hibernate, 3 = Shut down
    $newValue = if ($referenceValue -eq 0) { 1 } else { 0 }
    
    # Get friendly names for display
    $actionNames = @{
        0 = "Do nothing"
        1 = "Sleep"
        2 = "Hibernate"
        3 = "Shut down"
    }
    
    $currentAction = $actionNames[$referenceValue] ?? "Unknown ($referenceValue)"
    $newAction = $actionNames[$newValue] ?? "Unknown ($newValue)"
    
    Write-Host "`n=== TOGGLE DECISION ===" -ForegroundColor Cyan
    Write-Host "Current: $currentAction" -ForegroundColor White
    Write-Host "Toggling to: $newAction" -ForegroundColor Green
    
    # Apply changes to both AC and DC
    Write-Host "Applying changes..." -ForegroundColor Gray
    
    $dcResult = powercfg /setdcvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue 2>&1
    $acResult = powercfg /setacvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "DC Result: $dcResult" -ForegroundColor Red
        Write-Host "AC Result: $acResult" -ForegroundColor Red
        throw "Failed to apply lid close settings. Check GUID correctness."
    }
    
    # Apply the changes
    $applyResult = powercfg /setactive $powerScheme 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Apply Result: $applyResult" -ForegroundColor Red
        throw "Failed to activate changes"
    }
    
    # Verify the changes
    Start-Sleep -Seconds 1
    $verification = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    $verifiedDC = $null
    $verifiedAC = $null
    
    foreach ($line in $verification) {
        if ($line -match "Current\s+DC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
            $verifiedDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current\s+AC\s+Power\s+Setting\s+Index:\s*0x([0-9a-fA-F]+)") {
            $verifiedAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    if ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue) {
        Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
        Write-Host "Lid close action updated to: $newAction" -ForegroundColor White
        Write-Host "Battery (DC): $newAction" -ForegroundColor White
        Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
        
        # Save working GUIDs for future use
        @{
            SubgroupName = $guids.SubgroupName
            SubgroupGuid = $guids.SubgroupGuid
            SettingName = $guids.SettingName
            SettingGuid = $guids.SettingGuid
            VerifiedOn = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            WindowsVersion = [System.Environment]::OSVersion.Version.ToString()
        } | ConvertTo-Json | Out-File "working-lid-close-guids.json" -Encoding UTF8
        
    } else {
        Write-Host "`n=== VERIFICATION FAILED ===" -ForegroundColor Red
        Write-Host "Expected: DC=$newValue, AC=$newValue" -ForegroundColor Red
        Write-Host "Actual:   DC=$verifiedDC, AC=$verifiedAC" -ForegroundColor Red
        throw "Settings were not applied correctly"
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)
    
    SOLUTION: Run debug-lid-close-guids.ps1 to discover correct GUIDs for your system."
}