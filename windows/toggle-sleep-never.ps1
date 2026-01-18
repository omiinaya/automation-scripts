# Toggle sleep behavior on both battery and plugged in for Windows 11
# Refactored to use modular system - reduces from 35 lines to 18 lines

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
$modulePath = Join-Path $PSScriptRoot "..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-StatusMessage -Message "Administrator privileges required to modify power settings" -Type Error
    Invoke-Elevation
    exit
}

try {
    $powerScheme = (Get-ActivePowerScheme).GUID
    
    # Query current sleep settings
    $sleepSettings = powercfg -q $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da
    
    # Extract current values
    $dcLine = $sleepSettings | Select-String "DC.*Index.*0x" | Select-Object -First 1
    $acLine = $sleepSettings | Select-String "AC.*Index.*0x" | Select-Object -First 1
    
    # Parse hex values with proper error handling
    $currentDC = 900
    $currentAC = 900
    
    if ($dcLine -and $dcLine -match '.*Index.*0x([0-9a-fA-F]+)') {
        $currentDC = Convert-HexStringToInt -HexString $matches[1]
    }
    
    if ($acLine -and $acLine -match '.*Index.*0x([0-9a-fA-F]+)') {
        try {
            $currentAC = [Convert]::ToInt32($matches[1], 16)
        } catch {
            # Handle hex strings with leading zeros
            $cleanHex = $matches[1] -replace '^0+', ''
            if ([string]::IsNullOrEmpty($cleanHex)) { $cleanHex = '0' }
            $currentAC = [Convert]::ToInt32($cleanHex, 16)
        }
    }
    
    # Toggle logic
    $newDCValue = if ($currentDC -ne 0) { 0x0 } else { 900 }
    $newACValue = if ($currentAC -ne 0) { 0x0 } else { 900 }
    
    # Apply changes
    powercfg -setdcvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da $newDCValue
    powercfg -setacvalueindex $powerScheme 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da $newACValue
    Set-PowerScheme -SchemeGUID $powerScheme
    
    if ($newDCValue -eq 0) {
        Write-StatusMessage -Message "Sleep disabled for both battery and plugged in power" -Type Success
    } else {
        Write-StatusMessage -Message "Sleep re-enabled (15 minutes timeout)" -Type Success
    }
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle sleep settings: $($_.Exception.Message)"
}