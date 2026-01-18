# Toggle "Fade or slide ToolTips into view" setting
# This controls the checkbox in Performance Options > Visual Effects
# Manipulates the UserPreferencesMask binary value (bit 0x80)

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
    
    # Bit 0x80 (eighth bit in first byte) controls "Fade or slide ToolTips into view"
    # When bit is SET (1), fade/slide is ENABLED
    # When bit is CLEAR (0), fade/slide is DISABLED
    $fadeBit = 0x80
    
    # Check current state
    $isEnabled = ($currentMask[0] -band $fadeBit) -ne 0
    
    # Toggle the bit
    if ($isEnabled) {
        # Disable: Clear the bit
        $currentMask[0] = $currentMask[0] -band (-bnot $fadeBit)
        $newState = "disabled"
    } else {
        # Enable: Set the bit
        $currentMask[0] = $currentMask[0] -bor $fadeBit
        $newState = "enabled"
    }
    
    # Write back the modified mask
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $currentMask -Type Binary
    
    Write-StatusMessage -Message "Fade or slide ToolTips into view: $newState" -Type Success
    Write-StatusMessage -Message "Note: Changes may require restarting applications or signing out/in to take full effect" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle fade ToolTips setting: $($_.Exception.Message)"
}
