# Toggle "Show shadows under mouse pointer" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x10 in second byte)

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
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    $registryPath = "HKCU:\Control Panel\Desktop"
    $valueName = "UserPreferencesMask"
    
    # Get current UserPreferencesMask value (binary)
    $currentMask = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentMask) {
        throw "UserPreferencesMask value not found"
    }
    
    # Bit 0x10 in second byte (index 1) controls "Show shadows under mouse pointer"
    # When bit is SET (1), shadows are ENABLED
    # When bit is CLEAR (0), shadows are DISABLED
    $shadowBit = 0x10
    
    # Check current state
    $isEnabled = ($currentMask[1] -band $shadowBit) -ne 0
    
    # Toggle the bit
    if ($isEnabled) {
        # Disable: Clear the bit
        $currentMask[1] = $currentMask[1] -band (-bnot $shadowBit)
        $newState = "disabled"
    } else {
        # Enable: Set the bit
        $currentMask[1] = $currentMask[1] -bor $shadowBit
        $newState = "enabled"
    }
    
    # Write back the modified mask
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $currentMask -Type Binary
    
    Write-StatusMessage -Message "Show shadows under mouse pointer: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle shadows under mouse setting: $($_.Exception.Message)"
}
