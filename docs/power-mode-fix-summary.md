# Power Mode Toggle Script Fix Summary

## Problem Statement
The original power mode toggle script was using registry-based power mode detection but wasn't properly affecting the actual Windows power settings visible in Settings > System > Power & Battery.

## Root Cause Analysis
The issue was that while the registry keys being used were correct:
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayAc` (AC power)
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayDc` (DC power)

The script wasn't properly forcing Windows to recognize the registry changes and refresh the power settings UI.

## Fixes Implemented

### 1. Enhanced Registry Change Application
Modified [`Set-Windows11PowerMode`](modules/PowerManagement.psm1:167) function in [`PowerManagement.psm1`](modules/PowerManagement.psm1):

- Added power scheme refresh mechanism
- Temporarily switches to alternate power scheme and back to force Windows to recognize registry changes
- Ensures Settings UI reflects the changes immediately

### 2. Improved Power Mode Detection
Enhanced [`Get-Windows11PowerMode`](modules/PowerManagement.psm1:93) function:

- Added fallback logic for AC power mode detection
- Prioritizes AC mode when system is plugged in
- Better error handling for missing registry values

### 3. Focused AC Power Mode Changes
Updated [`toggle-power-mode.ps1`](windows/deferred/toggle-power-mode.ps1) script (moved to deferred folder):

- Specifically targets AC power ("Plugged In") mode changes
- Uses `-ApplyTo "AC"` parameter to focus on the requested power state
- Maintains toggle functionality between Balanced (0) and Best Performance (2)
- **Note**: Script moved to deferred folder as it requires further development

## Registry Values Explained

| Value | Mode | Description |
|-------|------|-------------|
| 0 | Balanced | Recommended power mode |
| 1 | Better Performance | Balanced performance |
| 2 | Best Performance | Maximum performance |

## Technical Details

### Registry Keys Used
- **AC Power**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayAc`
- **DC Power**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\PowerSchemes\ActiveOverlayAcDc\OverlayDc`

### Power Scheme Refresh Mechanism
```powershell
# Force Windows to recognize registry changes
$activeScheme = Get-ActivePowerScheme
if ($activeScheme) {
    # Temporarily switch to another scheme and back to refresh
    $schemes = Get-PowerSchemes
    $alternateScheme = $schemes | Where-Object { -not $_.Active } | Select-Object -First 1
    
    if ($alternateScheme) {
        # Switch to alternate scheme briefly
        Set-PowerScheme -SchemeGUID $alternateScheme.GUID
        # Switch back to original scheme
        Set-PowerScheme -SchemeGUID $activeScheme.GUID
    }
}
```

## Testing
Created [`power-mode-test.ps1`](tests/power-mode-test.ps1) to verify:
- Current power mode detection
- Battery status detection
- Power scheme enumeration
- Power mode setting functionality
- Registry change verification

## Expected Behavior
After running the fixed script:
1. Registry changes are made to the correct AC power mode settings
2. Windows power scheme is refreshed to recognize the changes
3. Settings > System > Power & Battery should reflect the new power mode
4. Toggle functionality works correctly between Balanced and Best Performance

## Files Modified
- [`modules/PowerManagement.psm1`](modules/PowerManagement.psm1) - Enhanced power mode functions
- [`windows/deferred/toggle-power-mode.ps1`](windows/deferred/toggle-power-mode.ps1) - Fixed toggle script (moved to deferred folder)
- [`tests/power-mode-test.ps1`](tests/power-mode-test.ps1) - Created test script

## Files Created
- [`docs/power-mode-fix-summary.md`](docs/power-mode-fix-summary.md) - This documentation

## Verification
The script now properly uses registry-based Windows power mode settings that should be reflected in the Windows Settings UI, specifically targeting AC power ("Plugged In") mode changes as requested.