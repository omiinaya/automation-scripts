<#
.SYNOPSIS
    Visual effects management module for Windows.
.DESCRIPTION
    Provides functions for managing Windows visual effects and refreshing Explorer settings
    without requiring a restart. Includes Windows API P/Invoke declarations for broadcasting
    system setting changes.
.NOTES
    File Name      : VisualEffects.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    
.EXAMPLE
    Import-Module .\modules\VisualEffects.psm1
    Invoke-ExplorerRefresh
    
.EXAMPLE
    Import-Module .\modules\ModuleIndex.psm1
    # Make registry changes
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0
    # Refresh Explorer to apply changes immediately
    Invoke-ExplorerRefresh
#>

# Add P/Invoke for Windows API functions to refresh Explorer settings
# This type is only added if it doesn't already exist
if (-not ([System.Management.Automation.PSTypeName]'Win32API').Type) {
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
}

function Invoke-ExplorerRefresh {
    <#
    .SYNOPSIS
        Refreshes Windows Explorer settings without requiring a restart.
    .DESCRIPTION
        Broadcasts Windows API messages to notify all applications and Explorer that
        system settings have changed. This uses multiple methods for maximum compatibility:
        
        1. Broadcasts WM_SETTINGCHANGE with "WindowMetrics" parameter
        2. Broadcasts WM_SETTINGCHANGE with "ImmersiveColorSet" parameter
        3. Notifies Shell of association changes using SHChangeNotify
        
        This function is particularly useful after making registry changes to visual
        effects settings, as it forces Explorer to reload its cached settings immediately.
    .PARAMETER Quiet
        Suppresses informational output. Only errors will be displayed.
    .EXAMPLE
        Invoke-ExplorerRefresh
        
        Refreshes Explorer settings with informational output.
    .EXAMPLE
        Invoke-ExplorerRefresh -Quiet
        
        Refreshes Explorer settings silently.
    .EXAMPLE
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0
        Invoke-ExplorerRefresh
        
        Changes a registry setting and immediately refreshes Explorer to apply it.
    .NOTES
        This function uses Windows API calls via P/Invoke to broadcast system messages.
        It does not require administrative privileges for most visual effect changes.
    .OUTPUTS
        None. This function does not return any output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )
    
    try {
        if (-not $Quiet) {
            Write-Verbose "Refreshing Explorer settings..."
        }
        
        # Method 1: Broadcast WM_SETTINGCHANGE to all windows with "WindowMetrics" parameter
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
            5000,  # 5 second timeout
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
        
        if (-not $Quiet) {
            Write-Verbose "Explorer settings refreshed successfully"
        }
    }
    catch {
        Write-Error "Failed to refresh Explorer settings: $($_.Exception.Message)"
        throw
    }
}

# Export module members
Export-ModuleMember -Function Invoke-ExplorerRefresh
