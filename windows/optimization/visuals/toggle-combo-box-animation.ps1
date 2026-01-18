# Toggle "Slide open combo boxes" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x08)

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
    
    # Bit 0x08 (fourth bit in first byte) controls "Slide open combo boxes"
    # When bit is SET (1), slide animation is ENABLED
    # When bit is CLEAR (0), slide animation is DISABLED
    $slideBit = 0x08
    
    # Check current state
    $isEnabled = ($currentMask[0] -band $slideBit) -ne 0
    
    # Toggle the bit
    if ($isEnabled) {
        # Disable: Clear the bit
        $currentMask[0] = $currentMask[0] -band (-bnot $slideBit)
        $newState = "disabled"
    } else {
        # Enable: Set the bit
        $currentMask[0] = $currentMask[0] -bor $slideBit
        $newState = "enabled"
    }
    
    # Write back the modified mask
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $currentMask -Type Binary
    
    Write-StatusMessage -Message "Slide open combo boxes: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle combo box animation setting: $($_.Exception.Message)"
}
