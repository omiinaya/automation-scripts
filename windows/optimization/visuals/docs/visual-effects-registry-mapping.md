# Visual Effects Registry and API Mapping

## UserPreferencesMask Structure

Location: `HKCU:\Control Panel\Desktop\UserPreferencesMask`
Type: REG_BINARY (8 bytes)

The UserPreferencesMask is an 8-byte binary value where each bit controls a specific visual effect.

### Bit Mapping (Based on Windows Documentation and Testing)

| Byte | Bit | Hex Value | Visual Effect | SPI Constant |
|------|-----|-----------|---------------|--------------|
| 0 | 0x01 | 0x01 | Keyboard cues (underline access keys) | SPI_SETKEYBOARDCUES |
| 0 | 0x02 | 0x02 | Menu animation | SPI_SETMENUANIMATION |
| 0 | 0x04 | 0x04 | Combo box animation | SPI_SETCOMBOBOXANIMATION |
| 0 | 0x08 | 0x08 | List box smooth scrolling | SPI_SETLISTBOXSMOOTHSCROLLING |
| 0 | 0x10 | 0x10 | Gradient captions | SPI_SETGRADIENTCAPTIONS |
| 0 | 0x20 | 0x20 | Keyboard cues (always show) | Related to SPI_SETKEYBOARDCUES |
| 0 | 0x40 | 0x40 | Hot tracking | SPI_SETHOTTRACKING |
| 0 | 0x80 | 0x80 | Reserved | - |
| 1 | 0x01 | 0x01 | Menu fade | SPI_SETMENUFADE |
| 1 | 0x02 | 0x02 | Selection fade | SPI_SETSELECTIONFADE |
| 1 | 0x04 | 0x04 | Tooltip animation | SPI_SETTOOLTIPANIMATION |
| 1 | 0x08 | 0x08 | Tooltip fade | SPI_SETTOOLTIPFADE |
| 1 | 0x10 | 0x10 | Cursor shadow | SPI_SETCURSORSHADOW |
| 1 | 0x20 | 0x20 | Mouse click lock | SPI_SETMOUSECLICKLOCK |
| 1 | 0x40 | 0x40 | Reserved | - |
| 1 | 0x80 | 0x80 | UI Effects (master switch) | SPI_SETUIEFFECTS |
| 2 | 0x01 | 0x01 | Reserved | - |
| 2 | 0x02 | 0x02 | Flat menus | SPI_SETFLATMENU |
| 2 | 0x04 | 0x04 | Drop shadow | SPI_SETDROPSHADOW |
| 2 | 0x08 | 0x08 | Reserved | - |
| 2 | 0x10 | 0x10 | Reserved | - |
| 2 | 0x20 | 0x20 | Reserved | - |
| 2 | 0x40 | 0x40 | Reserved | - |
| 2 | 0x80 | 0x80 | Reserved | - |
| 3 | 0x01 | 0x01 | Font smoothing | SPI_SETFONTSMOOTHING |
| 3 | 0x02 | 0x02 | ClearType | SPI_SETCLEARTYPE |
| 3 | 0x04 | 0x04 | Reserved | - |
| 3 | 0x08 | 0x08 | Reserved | - |
| 3 | 0x10 | 0x10 | Reserved | - |
| 3 | 0x20 | 0x20 | Reserved | - |
| 3 | 0x40 | 0x40 | Reserved | - |
| 3 | 0x80 | 0x80 | Reserved | - |

## Other Registry Locations

### Window Animations
- **Location**: `HKCU:\Control Panel\Desktop\WindowMetrics\MinAnimate`
- **Type**: REG_SZ
- **Values**: "0" (disabled) or "1" (enabled)
- **SPI Constant**: SPI_SETANIMATION (uses ANIMATIONINFO structure)

### Drag Full Windows
- **Location**: `HKCU:\Control Panel\Desktop\DragFullWindows`
- **Type**: REG_SZ
- **Values**: "0" (disabled) or "1" (enabled)
- **SPI Constant**: SPI_SETDRAGFULLWINDOWS

### Show Window Contents While Dragging
- Same as Drag Full Windows

### Taskbar Animations
- Controlled by UserPreferencesMask (needs verification of exact bit)
- May also be affected by SPI_SETANIMATION

### Translucent Selection Rectangle
- **Location**: `HKCU:\Software\Microsoft\Windows\DWM\AlphaSelectRect`
- **Type**: REG_DWORD
- **Values**: 0 (disabled/opaque) or 1 (enabled/translucent)
- **Note**: Requires DWM restart (UxSms service) to take effect immediately

### Peek (Aero Peek)
- **Location**: `HKCU:\Software\Microsoft\Windows\DWM\EnableAeroPeek`
- **Type**: REG_DWORD
- **Values**: 0 (disabled) or 1 (enabled)
- **Note**: Requires DWM restart or logoff/logon

### Transparency (Aero Glass)
- **Location**: `HKCU:\Software\Microsoft\Windows\DWM\ColorizationOpaqueBlend`
- **Type**: REG_DWORD
- **Values**: 0 (transparent) or 1 (opaque)
- **Note**: Requires DWM restart or logoff/logon

### Thumbnails
- **Location**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\IconsOnly`
- **Type**: REG_DWORD
- **Values**: 0 (show thumbnails) or 1 (show icons only)
- **Note**: Requires Explorer restart

### Taskbar Thumbnails
- **Location**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ExtendedUIHoverTime`
- **Type**: REG_DWORD
- **Values**: Time in milliseconds (default 400)
- **Note**: Setting to very high value effectively disables

### Icon Shadows
- **Location**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ListviewShadow`
- **Type**: REG_DWORD
- **Values**: 0 (disabled) or 1 (enabled)
- **Note**: Requires Explorer restart

### Shadows Under Windows
- Controlled by UserPreferencesMask bit 2.0x04 (Drop shadow)
- **SPI Constant**: SPI_SETDROPSHADOW

### Shadows Under Mouse Pointer
- Controlled by UserPreferencesMask bit 1.0x10 (Cursor shadow)
- **SPI Constant**: SPI_SETCURSORSHADOW

### Smooth Scrolling
- **Location**: `HKCU:\Control Panel\Desktop\SmoothScroll`
- **Type**: REG_DWORD
- **Values**: 0 (disabled) or 1 (enabled)
- Also controlled by UserPreferencesMask bit 0.0x08 (List box smooth scrolling)

## SystemParametersInfo Constants

```cpp
#define SPI_SETANIMATION           0x0049
#define SPI_SETDRAGFULLWINDOWS     0x0025
#define SPI_SETUIEFFECTS           0x103F
#define SPI_SETCOMBOBOXANIMATION   0x1005
#define SPI_SETCURSORSHADOW        0x101B
#define SPI_SETDROPSHADOW          0x1025
#define SPI_SETFLATMENU            0x1023
#define SPI_SETFONTSMOOTHING       0x004B
#define SPI_SETGRADIENTCAPTIONS    0x1009
#define SPI_SETHOTTRACKING         0x100F
#define SPI_SETKEYBOARDCUES        0x100B
#define SPI_SETLISTBOXSMOOTHSCROLLING 0x1007
#define SPI_SETMENUANIMATION       0x1003
#define SPI_SETMENUFADE            0x1013
#define SPI_SETSELECTIONFADE       0x1015
#define SPI_SETTOOLTIPANIMATION    0x1017
#define SPI_SETTOOLTIPFADE         0x1019
#define SPI_SETCLEARTYPE           0x1049
```

## fWinIni Flags

```cpp
#define SPIF_UPDATEINIFILE  0x0001  // Write to user profile
#define SPIF_SENDCHANGE     0x0002  // Broadcast WM_SETTINGCHANGE
#define SPIF_SENDWININICHANGE 0x0002  // Same as SPIF_SENDCHANGE
```

For immediate effect, use: `SPIF_UPDATEINIFILE | SPIF_SENDCHANGE` (0x0003)

## Notes

1. When modifying UserPreferencesMask, always read the current value, modify only the specific bit(s), and write back
2. Use SystemParametersInfo with proper SPI constants for immediate effect
3. Some effects require Explorer or DWM restart to take effect
4. The master UI Effects switch (byte 1, bit 0x80) should generally be enabled for individual effects to work
