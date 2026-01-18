# Translucent Selection Explorer Refresh Fix

## Problem
The [`toggle-translucent-selection.ps1`](../toggle-translucent-selection.ps1) script correctly modified the `ListviewAlphaSelect` registry value, but changes didn't take effect until Explorer was restarted. This caused a jarring user experience with Explorer windows closing and reopening.

## Solution
Instead of restarting Explorer, the script now uses proper Windows API calls to notify Explorer and other applications of the setting change, mimicking what the Performance Options dialog does internally.

## Implementation Details

### Windows API Functions Used

#### 1. SendMessageTimeout (user32.dll)
Broadcasts `WM_SETTINGCHANGE` messages to all top-level windows with a timeout to prevent hanging.

**Parameters used:**
- `hWnd`: `HWND_BROADCAST` (0xFFFF) - sends to all top-level windows
- `Msg`: `WM_SETTINGCHANGE` (0x001A) - notifies of system setting changes
- `lParam`: Two different parameters are sent:
  - `"WindowMetrics"` - notifies of window metric changes
  - `"ImmersiveColorSet"` - refreshes modern Windows visual elements
- `fuFlags`: `SMTO_ABORTIFHUNG` (0x0002) - returns if receiving window is hung
- `uTimeout`: 5000 ms - prevents indefinite blocking

**Why two messages?**
- `WindowMetrics`: Traditional parameter for visual effect changes
- `ImmersiveColorSet`: Ensures modern Windows UI elements also refresh

#### 2. SHChangeNotify (shell32.dll)
Notifies the Shell that a system-wide change has occurred.

**Parameters used:**
- `wEventId`: `SHCNE_ASSOCCHANGED` (0x08000000) - file type associations changed
- `uFlags`: `SHCNF_IDLIST | SHCNF_FLUSH` - flush the notification immediately
- `dwItem1`, `dwItem2`: NULL - not needed for this event type

**Why SHCNE_ASSOCCHANGED?**
This event forces Explorer to invalidate its cached settings and refresh, which is exactly what we need for visual effect changes to take effect.

## Technical Background

### What Performance Options Does
When you toggle "Show translucent selection rectangle" in Performance Options:
1. Modifies `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ListviewAlphaSelect`
2. Broadcasts `WM_SETTINGCHANGE` with appropriate parameters
3. Calls `SHChangeNotify` to refresh Shell components
4. Changes take effect immediately without restart

### Registry Value
- **Path**: `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
- **Value**: `ListviewAlphaSelect`
- **Type**: DWORD
- **Values**:
  - `1` = Enabled (translucent/alpha-blended selection rectangle)
  - `0` = Disabled (opaque selection rectangle)

## Benefits

### Before Fix
- ❌ Required Explorer restart
- ❌ All Explorer windows closed and reopened
- ❌ Jarring user experience
- ❌ Lost window positions and states
- ❌ Interrupted workflow

### After Fix
- ✅ Changes take effect immediately
- ✅ No Explorer restart needed
- ✅ Smooth user experience
- ✅ Windows remain open
- ✅ Workflow uninterrupted
- ✅ Matches Performance Options behavior

## Code Structure

```powershell
# 1. Define Windows API functions
Add-Type @"
public class Win32API {
    // SendMessageTimeout for WM_SETTINGCHANGE
    [DllImport("user32.dll", ...)]
    public static extern IntPtr SendMessageTimeout(...);
    
    // SHChangeNotify for Shell refresh
    [DllImport("shell32.dll", ...)]
    public static extern void SHChangeNotify(...);
}
"@

# 2. Modify registry value
Set-ItemProperty -Path $registryPath -Name "ListviewAlphaSelect" -Value $newValue

# 3. Broadcast WM_SETTINGCHANGE with "WindowMetrics"
[Win32API]::SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, "WindowMetrics", ...)

# 4. Broadcast WM_SETTINGCHANGE with "ImmersiveColorSet"
[Win32API]::SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, "ImmersiveColorSet", ...)

# 5. Notify Shell of changes
[Win32API]::SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_FLUSH, ...)
```

## Testing

To verify the fix works:

1. Open File Explorer and select multiple files/folders
2. Note the current selection rectangle appearance (translucent or opaque)
3. Run the script: `.\toggle-translucent-selection.ps1`
4. Without closing Explorer, select files/folders again
5. The selection rectangle appearance should change immediately

## References

### Microsoft Documentation
- [SendMessageTimeout function](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw)
- [SHChangeNotify function](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shchangenotify)
- [WM_SETTINGCHANGE message](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-settingchange)

### Related Scripts
- [`toggle-animate-windows.ps1`](../toggle-animate-windows.ps1) - Uses SystemParametersInfo API
- [`toggle-window-contents-dragging.ps1`](../toggle-window-contents-dragging.ps1) - Uses SystemParametersInfo API

## Notes

- The 5-second timeout prevents the script from hanging if a window is unresponsive
- Using `SMTO_ABORTIFHUNG` ensures we don't wait for hung windows
- Multiple notification methods ensure maximum compatibility across Windows versions
- The `SHCNF_FLUSH` flag ensures notifications are processed immediately
