# Translucent Selection Rectangle Fix

## Issue
The [`toggle-translucent-selection.ps1`](../toggle-translucent-selection.ps1) script was incorrectly trying to manipulate the UserPreferencesMask binary value (bit 0x80 in byte 1), which actually controls the "UI Effects master switch", not the translucent selection rectangle.

## Root Cause
The "Show translucent selection rectangle" setting in Windows Performance Options is controlled by a DWM (Desktop Window Manager) registry value, not a UserPreferencesMask bit.

## Solution

### Correct Registry Location
- **Path**: `HKCU:\Software\Microsoft\Windows\DWM\AlphaSelectRect`
- **Type**: REG_DWORD
- **Values**: 
  - `1` = Enabled (translucent/alpha-blended selection rectangle)
  - `0` = Disabled (opaque selection rectangle)

### Implementation Details

1. **Registry Path**: The setting is stored in the DWM registry key, not in Control Panel\Desktop
2. **Value Type**: DWORD (not binary like UserPreferencesMask)
3. **Default Behavior**: If the value doesn't exist, Windows defaults to enabled (1)
4. **Immediate Effect**: Requires restarting the UxSms service (Desktop Window Manager) to apply changes immediately

### Script Changes

The updated script now:
1. Checks/creates the `HKCU:\Software\Microsoft\Windows\DWM` registry path
2. Reads the current `AlphaSelectRect` value (defaults to 1 if not set)
3. Toggles between 0 and 1
4. Restarts the UxSms service to apply changes immediately

### Testing Notes

This setting controls the visual appearance of the selection rectangle that appears when you:
- Click and drag on the desktop to select multiple icons
- Click and drag in Windows Explorer to select multiple files
- Use the lasso selection tool in various Windows applications

When enabled (1), the rectangle has a translucent/alpha-blended appearance.
When disabled (0), the rectangle is opaque with a solid border.

## References

- Windows Performance Options: Control Panel → System → Advanced system settings → Performance Settings → Visual Effects
- DWM Registry Settings: `HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM`
- Related Settings: Other DWM visual effects like Aero Peek, transparency, etc.

## Related Files
- [`toggle-translucent-selection.ps1`](../toggle-translucent-selection.ps1) - Fixed script
- [`visual-effects-registry-mapping.md`](visual-effects-registry-mapping.md) - Updated documentation
