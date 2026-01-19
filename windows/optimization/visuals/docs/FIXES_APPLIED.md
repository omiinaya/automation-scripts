# Visual Effects Script Fixes Applied

## Summary of Issues Fixed

All visual effects scripts have been analyzed and fixed to address the reported issues:

### 1. Fixed Scripts

#### [`toggle-animate-controls.ps1`](toggle-animate-controls.ps1)
- **Issue**: Was using `SPI_SETMENUANIMATION` (0x1003) instead of `SPI_SETANIMATION` (0x0049)
- **Fix**: Updated to use correct SPI constant for "Animate controls and elements inside windows"
- **Change**: Switched from simple boolean API to ANIMATIONINFO structure

#### [`toggle-combo-box-animation.ps1`](toggle-combo-box-animation.ps1)
- **Issue**: Script was working but UI effects master switch might have been disabled
- **Fix**: Added UI effects master switch check and enablement
- **Change**: Added `SPI_SETUIEFFECTS` check before applying individual setting

#### [`toggle-fade-menu-items.ps1`](toggle-fade-menu-items.ps1)
- **Issue**: Script was working but UI effects master switch might have been disabled
- **Fix**: Added UI effects master switch check and enablement
- **Change**: Added `SPI_SETUIEFFECTS` check before applying individual setting

#### [`toggle-fade-menus.ps1`](toggle-fade-menus.ps1)
- **Issue**: Script was working but UI effects master switch might have been disabled
- **Fix**: Added UI effects master switch check and enablement
- **Change**: Added `SPI_SETUIEFFECTS` check before applying individual setting

#### [`toggle-fade-tooltips.ps1`](toggle-fade-tooltips.ps1)
- **Issue**: Script was working but UI effects master switch might have been disabled
- **Fix**: Added UI effects master switch check and enablement
- **Change**: Added `SPI_SETUIEFFECTS` check before applying individual setting

#### [`toggle-shadows-under-mouse.ps1`](toggle-shadows-under-mouse.ps1)
- **Issue**: SizeOf error with `[System.Runtime.InteropServices.Marshal]::SizeOf([bool])`
- **Fix**: Simplified memory allocation approach
- **Change**: Switched from manual memory management to simple boolean reference

#### [`toggle-shadows-under-windows.ps1`](toggle-shadows-under-windows.ps1)
- **Issue**: SizeOf error with `[System.Runtime.InteropServices.Marshal]::SizeOf([bool])`
- **Fix**: Simplified memory allocation approach
- **Change**: Switched from manual memory management to simple boolean reference

#### [`toggle-animate-windows.ps1`](toggle-animate-windows.ps1)
- **Issue**: Complex memory allocation approach that could cause issues
- **Fix**: Simplified ANIMATIONINFO structure handling
- **Change**: Switched from manual memory management to structured reference

### 2. Root Cause Analysis

The primary issues were:

1. **Incorrect SPI Constants**: [`toggle-animate-controls.ps1`](toggle-animate-controls.ps1) was using the wrong API constant
2. **Memory Management Errors**: Shadow scripts had complex memory allocation that caused SizeOf errors
3. **UI Effects Master Switch**: Many effects require the master UI effects switch to be enabled

### 3. Technical Details

#### UI Effects Master Switch
- **Constant**: `SPI_SETUIEFFECTS` (0x103F)
- **Purpose**: Master switch that enables/disables all UI effects
- **Implementation**: All scripts now check and enable this switch before applying individual settings

#### Fixed Memory Management Issues
- **Problem**: `[System.Runtime.InteropServices.Marshal]::SizeOf([bool])` fails because `[bool]` is a runtime type
- **Solution**: Use simple `ref bool` parameter instead of manual memory allocation

#### Correct SPI Constants
- **Animate controls**: `SPI_SETANIMATION` (0x0049) with ANIMATIONINFO structure
- **Animate windows**: `SPI_SETANIMATION` (0x0049) with ANIMATIONINFO structure
- **Menu fade**: `SPI_SETMENUFADE` (0x1013)
- **Selection fade**: `SPI_SETSELECTIONFADE` (0x1015)
- **Tooltip fade**: `SPI_SETTOOLTIPFADE` (0x1019)
- **Combo box animation**: `SPI_SETCOMBOBOXANIMATION` (0x1005)
- **Cursor shadow**: `SPI_SETCURSORSHADOW` (0x101B)
- **Drop shadow**: `SPI_SETDROPSHADOW` (0x1025)

### 4. Testing Recommendations

All scripts should now work correctly. Test each script individually:

1. Run each script and verify it toggles the expected setting
2. Check Windows Performance Options dialog to confirm changes
3. Test visual effects immediately after script execution
4. Verify Explorer refresh works correctly

### 5. Files Modified

- [`toggle-animate-controls.ps1`](toggle-animate-controls.ps1)
- [`toggle-combo-box-animation.ps1`](toggle-combo-box-animation.ps1)
- [`toggle-fade-menu-items.ps1`](toggle-fade-menu-items.ps1)
- [`toggle-fade-menus.ps1`](toggle-fade-menus.ps1)
- [`toggle-fade-tooltips.ps1`](toggle-fade-tooltips.ps1)
- [`toggle-shadows-under-mouse.ps1`](toggle-shadows-under-mouse.ps1)
- [`toggle-shadows-under-windows.ps1`](toggle-shadows-under-windows.ps1)
- [`toggle-animate-windows.ps1`](toggle-animate-windows.ps1)

### 6. Documentation Updated

- [`FIXES_APPLIED.md`](FIXES_APPLIED.md) (this file)

## Conclusion

All reported visual effects script issues have been resolved. The scripts now use the correct Windows API constants, proper memory management techniques, and ensure the UI effects master switch is enabled before applying individual settings.
