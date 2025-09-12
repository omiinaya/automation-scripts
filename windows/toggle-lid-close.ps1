# Toggle lid close behavior between "Do nothing" and "Sleep" for Windows 11
# Repaired version with proper GUID discovery and error handling

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
        $cleanHex = $HexString -replace '^0x', '' -replace '^0+', ''
        if ([string]::IsNullOrEmpty($cleanHex)) { $cleanHex = '0' }
        return [Convert]::ToInt32($cleanHex, 16)
    } catch {
        return $null
    }
}

# Function to discover correct GUIDs for lid close action
function Get-LidCloseGUIDs {
    Write-Host "`n=== Discovering Lid Close GUIDs ===" -ForegroundColor Yellow
    
    # Standard Windows GUIDs for lid close action
    $standardGUIDs = @{
        SubgroupName = "Power buttons and lid"
        SubgroupGuid = "4f971e89-eebd-4455-a8de-9e59040e7347"
        SettingName = "Lid close action"
        SettingGuid = "5ca83367-6e45-459f-a27b-476b1d01c936"
    }
    
    # Get active power scheme
    $activeScheme = powercfg /getactivescheme
    if ($activeScheme -match "([0-9a-fA-F\-]{36})") {
        $powerScheme = $matches[1]
        Write-Host "Active Power Scheme: $powerScheme" -ForegroundColor Green
    } else {
        throw "Could not determine active power scheme"
    }
    
    # Test the standard GUIDs
    Write-Host "Testing standard GUIDs..." -ForegroundColor Gray
    $testResult = powercfg /query $powerScheme $standardGUIDs.SubgroupGuid $standardGUIDs.SettingGuid 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Standard GUIDs are valid" -ForegroundColor Green
        return $standardGUIDs
    }
    
    # If standard GUIDs fail, do comprehensive discovery
    Write-Host "  ✗ Standard GUIDs failed, running comprehensive discovery..." -ForegroundColor Yellow
    
    # Get all power settings
    $allSettings = powercfg /query
    
    $found = @()
    
    foreach ($line in $allSettings) {
        if ($line -match "SUBGROUP\s+([0-9a-fA-F\-]{36})\s+\(([^)]+)\)") {
            $subgroupGuid = $matches[1]
            $subgroupName = $matches[2]
            
            # Look for lid-related subgroups
            if ($subgroupName -like "*lid*" -or $subgroupName -like "*button*" -or $subgroupName -like "*power*") {
                $subgroupDetails = powercfg /query $powerScheme $subgroupGuid
                
                foreach ($detailLine in $subgroupDetails) {
                    if ($detailLine -match "POWER\s+SETTING\s+([0-9a-fA-F\-]{36})\s+\(([^)]*lid[^)]*)\)") {
                        $settingGuid = $matches[1]
                        $settingName = $matches[2]
                        
                        $found += @{
                            SubgroupName = $subgroupName
                            SubgroupGuid = $subgroupGuid
                            SettingName = $settingName
                            SettingGuid = $settingGuid
                        }
                    }
                }
            }
        }
    }
    
    if ($found.Count -gt 0) {
        Write-Host "Found lid settings:" -ForegroundColor Green
        foreach ($item in $found) {
            Write-Host "  Subgroup: $($item.SubgroupName) ($($item.SubgroupGuid))" -ForegroundColor Cyan
            Write-Host "  Setting: $($item.SettingName) ($($item.SettingGuid))" -ForegroundColor Cyan
        }
        return $found[0]
    }
    
    throw "Could not find lid close settings GUIDs"
}

# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required to modify power settings" -ForegroundColor Red
    
    # Request elevation
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
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
    # Get the correct GUIDs
    $guids = Get-LidCloseGUIDs
    
    # Get active power scheme
    $activeScheme = powercfg /getactivescheme
    if ($activeScheme -match "([0-9a-fA-F\-]{36})") {
        $powerScheme = $matches[1]
    } else {
        throw "Could not determine active power scheme"
    }
    
    $lidCloseGUID = $guids.SettingGuid
    $powerSettingSubgroup = $guids.SubgroupGuid
    
    Write-Host "`n=== LID CLOSE TOGGLE ===" -ForegroundColor Cyan
    Write-Host "Active Power Scheme: $powerScheme" -ForegroundColor Gray
    Write-Host "Using GUIDs: $powerSettingSubgroup + $lidCloseGUID" -ForegroundColor Gray
    
    # Get current settings
    $currentSettings = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    $currentDC = $null
    $currentAC = $null
    
    foreach ($line in $currentSettings) {
        if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $currentDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $currentAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    if ($null -eq $currentDC -or $null -eq $currentAC) {
        Write-Host "Raw powercfg output:" -ForegroundColor Gray
        $currentSettings | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        throw "Failed to parse current lid close settings"
    }
    
    Write-Host "`nCurrent lid close settings:" -ForegroundColor Cyan
    Write-Host "  DC (Battery): $currentDC" -ForegroundColor White
    Write-Host "  AC (Plugged in): $currentAC" -ForegroundColor White
    
    # Action mapping
    $actions = @{
        0 = "Do nothing"
        1 = "Sleep"
        2 = "Hibernate"
        3 = "Shut down"
    }
    
    $currentDCAction = $actions[$currentDC] ?? "Unknown ($currentDC)"
    $currentACAction = $actions[$currentAC] ?? "Unknown ($currentAC)"
    
    Write-Host "  DC Action: $currentDCAction" -ForegroundColor White
    Write-Host "  AC Action: $currentACAction" -ForegroundColor White
    
    # Toggle logic
    if ($currentDC -ne $currentAC) {
        Write-Host "`nWarning: AC and DC settings are inconsistent. Syncing to same value..." -ForegroundColor Yellow
    }
    
    $referenceValue = $currentAC
    $newValue = if ($referenceValue -eq 0) { 1 } else { 0 }
    
    $newAction = $actions[$newValue] ?? "Unknown ($newValue)"
    
    Write-Host "`n=== TOGGLE DECISION ===" -ForegroundColor Cyan
    Write-Host "Current: $($actions[$referenceValue] ?? "Unknown ($referenceValue)")" -ForegroundColor White
    Write-Host "Toggling to: $newAction" -ForegroundColor Green
    
    # Apply changes
    Write-Host "`nApplying changes..." -ForegroundColor Gray
    
    $dcResult = powercfg /setdcvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    $acResult = powercfg /setacvalueindex $powerScheme $powerSettingSubgroup $lidCloseGUID $newValue
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply changes. Exit code: $LASTEXITCODE"
    }
    
    # Activate changes
    $applyResult = powercfg /setactive $powerScheme
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to activate changes. Exit code: $LASTEXITCODE"
    }
    
    # Verify changes
    Start-Sleep -Seconds 1
    $verification = powercfg /query $powerScheme $powerSettingSubgroup $lidCloseGUID
    
    $verifiedDC = $null
    $verifiedAC = $null
    
    foreach ($line in $verification) {
        if ($line -match "Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedDC = Convert-HexStringToInt -HexString $matches[1]
        }
        if ($line -match "Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)") {
            $verifiedAC = Convert-HexStringToInt -HexString $matches[1]
        }
    }
    
    if ($verifiedDC -eq $newValue -and $verifiedAC -eq $newValue) {
        Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
        Write-Host "Lid close action updated to: $newAction" -ForegroundColor White
        Write-Host "Battery (DC): $newAction" -ForegroundColor White
        Write-Host "Plugged in (AC): $newAction" -ForegroundColor White
        
        # Save working GUIDs
        $guidInfo = @{
            SubgroupName = $guids.SubgroupName
            SubgroupGuid = $guids.SubgroupGuid
            SettingName = $guids.SettingName
            SettingGuid = $guids.SettingGuid
            VerifiedOn = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            WindowsVersion = [System.Environment]::OSVersion.Version.ToString()
        }
        $guidInfo | ConvertTo-Json | Out-File "working-lid-close-guids.json" -Encoding UTF8
        
    } else {
        Write-Host "`n=== VERIFICATION FAILED ===" -ForegroundColor Red
        Write-Host "Expected: DC=$newValue, AC=$newValue" -ForegroundColor Red
        Write-Host "Actual:   DC=$verifiedDC, AC=$verifiedAC" -ForegroundColor Red
        throw "Verification failed - settings may not have been applied correctly"
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle lid close settings: $($_.Exception.Message)"
}