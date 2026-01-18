# Toggle "Show translucent selection rectangle" setting
# This controls the checkbox in Performance Options > Visual Effects
# Controls whether the selection rectangle has a translucent/alpha-blended appearance

# Function to pause on error
function Wait-OnError {
    param(
        [string]$ErrorMessage
    )
    Write-Host "`nERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}

# Add P/Invoke for Windows API functions to refresh Explorer settings
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32API {
    // SendMessageTimeout for broadcasting WM_SETTINGCHANGE
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult
    );
    
    // SHChangeNotify to notify Shell of changes
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern void SHChangeNotify(
        int wEventId,
        uint uFlags,
        IntPtr dwItem1,
        IntPtr dwItem2
    );
    
    // Constants
    public const int HWND_BROADCAST = 0xFFFF;
    public const uint WM_SETTINGCHANGE = 0x001A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;
    public const int SHCNE_ASSOCCHANGED = 0x08000000;
    public const uint SHCNF_IDLIST = 0x0000;
    public const uint SHCNF_FLUSH = 0x1000;
}
"@

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

try {
    # The translucent selection rectangle is controlled by ListviewAlphaSelect
    # This is the actual registry value that Performance Options UI modifies
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $valueName = "ListviewAlphaSelect"
    
    # Ensure the registry path exists
    if (-not (Test-Path $registryPath)) {
        Write-StatusMessage -Message "Creating registry path: $registryPath" -Type Info
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Get current value (default to 1/enabled if not set)
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    
    if ($null -eq $currentValue) {
        # If value doesn't exist, assume it's enabled (Windows default)
        Write-StatusMessage -Message "Registry value not found, assuming enabled (Windows default)" -Type Info
        $currentValue = 1
    }
    
    # Display current state
    $currentState = if ($currentValue -eq 1) { "enabled" } else { "disabled" }
    Write-StatusMessage -Message "Current state: $currentState" -Type Info
    
    # Toggle the setting
    # 1 = Enabled (translucent selection rectangle)
    # 0 = Disabled (opaque selection rectangle)
    $newValue = if ($currentValue -eq 1) { 0 } else { 1 }
    $newState = if ($newValue -eq 1) { "enabled" } else { "disabled" }
    
    # Apply the new setting
    Write-StatusMessage -Message "Setting ListviewAlphaSelect to $newValue ($newState)..." -Type Info
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $newValue -Type DWord
    
    # Verify the change was applied
    $verifyValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
    if ($verifyValue -ne $newValue) {
        throw "Registry value verification failed. Expected: $newValue, Got: $verifyValue"
    }
    
    # Notify Explorer of the changes using multiple methods for maximum compatibility
    Write-StatusMessage -Message "Refreshing Explorer settings..." -Type Info
    
    # Method 1: Broadcast WM_SETTINGCHANGE to all windows
    # This notifies all applications that a system setting has changed
    $result = [UIntPtr]::Zero
    $hwndBroadcast = [IntPtr]::new([Win32API]::HWND_BROADCAST)
    [Win32API]::SendMessageTimeout(
        $hwndBroadcast,
        [Win32API]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "WindowMetrics",
        [Win32API]::SMTO_ABORTIFHUNG,
        5000,  # 5 second timeout
        [ref]$result
    ) | Out-Null
    
    # Method 2: Send WM_SETTINGCHANGE with "ImmersiveColorSet" parameter
    # This helps refresh visual elements in modern Windows
    [Win32API]::SendMessageTimeout(
        $hwndBroadcast,
        [Win32API]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "ImmersiveColorSet",
        [Win32API]::SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    ) | Out-Null
    
    # Method 3: Notify Shell of association changes
    # This forces Explorer to refresh its cached settings
    [Win32API]::SHChangeNotify(
        [Win32API]::SHCNE_ASSOCCHANGED,
        [Win32API]::SHCNF_IDLIST -bor [Win32API]::SHCNF_FLUSH,
        [IntPtr]::Zero,
        [IntPtr]::Zero
    )
    
    Write-StatusMessage -Message "Show translucent selection rectangle: $newState" -Type Success
    Write-StatusMessage -Message "Changes applied immediately - no Explorer restart required" -Type Info
    
} catch {
    Wait-OnError -ErrorMessage "Failed to toggle translucent selection setting: $($_.Exception.Message)"
}
