# Toggle "Fade out menu items after clicking" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x04 in second byte)

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
    
    # Bit 0x04 in second byte (index 1) controls "Fade out menu items after clicking"
    # When bit is SET (1), fade out is ENABLED
    # When bit is CLEAR (0), fade out is DISABLED
    $fadeBit = 0x04
    
    # Check current state
    $isEnabled = ($currentMask[1] -band $fadeBit) -ne 0
    
    # Toggle the bit
    if ($isEnabled) {
        # Disable: Clear the bit
        $currentMask[1] = $currentMask[1] -band (-bnot $fadeBit)
        $newState = "disabled"
    } else {
        # Enable: Set the bit
        $currentMask[1] = $currentMask[1] -bor $fadeBit
        $newState = "enabled"
    }
    
    # Write back the modified mask
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $currentMask -Type Binary
    
    Write-StatusMessage -Message "Fade out menu items after clicking: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle fade menu items setting: $($_.Exception.Message)"
}
