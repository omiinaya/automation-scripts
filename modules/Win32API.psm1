<#
.SYNOPSIS
    Win32 API utility functions for PowerShell automation scripts.
.DESCRIPTION
    Provides centralized P/Invoke declarations and wrapper functions for Windows API calls
    to eliminate code duplication across scripts.
.NOTES
    File Name      : Win32API.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import CommonUtilities for error handling patterns
$originalVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module "$PSScriptRoot\CommonUtilities.psm1" -Force -WarningAction SilentlyContinue -Verbose:$false
$VerbosePreference = $originalVerbosePreference

# Function to initialize ANIMATIONINFO structure
function Initialize-AnimationInfo {
    <#
    .SYNOPSIS
        Initializes the ANIMATIONINFO structure for Windows API calls.
    .DESCRIPTION
        Creates the ANIMATIONINFO struct type if not already defined.
    .EXAMPLE
        Initialize-AnimationInfo
    .OUTPUTS
        None. Creates the type definition.
    #>
    param()
    
    if (-not ([System.Management.Automation.PSTypeName]'ANIMATIONINFO').Type) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct ANIMATIONINFO {
    public uint cbSize;
    public int iMinAnimate;
}
"@
    }
}

# Function to set animation info
function Set-AnimationInfo {
    <#
    .SYNOPSIS
        Sets the window animation settings using Win32 API.
    .DESCRIPTION
        Uses SystemParametersInfo to configure window minimize/maximize animations.
    .PARAMETER EnableAnimation
        Enable or disable animations (default: $true).
    .EXAMPLE
        Set-AnimationInfo -EnableAnimation $false
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [bool]$EnableAnimation = $true
    )
    
    Initialize-AnimationInfo
    
    $animInfo = New-Object ANIMATIONINFO
    $animInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($animInfo.GetType())
    $animInfo.iMinAnimate = if ($EnableAnimation) { 1 } else { 0 }
    
    $result = [Win32API]::SystemParametersInfo(0x1003, $animInfo.cbSize, [ref]$animInfo, 0)
    return $result
}

# Function to initialize Win32 API types
function Initialize-Win32API {
    <#
    .SYNOPSIS
        Initializes common Win32 API types and methods.
    .DESCRIPTION
        Creates the Win32API class with common P/Invoke declarations.
    .EXAMPLE
        Initialize-Win32API
    .OUTPUTS
        None. Creates the type definition.
    #>
    param()
    
    if (-not ([System.Management.Automation.PSTypeName]'Win32API').Type) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32API {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetLocalTime(ref SYSTEMTIME lpSystemTime);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern void GetLocalTime(out SYSTEMTIME lpSystemTime);
}

[StructLayout(LayoutKind.Sequential)]
public struct SYSTEMTIME {
    public ushort wYear;
    public ushort wMonth;
    public ushort wDayOfWeek;
    public ushort wDay;
    public ushort wHour;
    public ushort wMinute;
    public ushort wSecond;
    public ushort wMilliseconds;
}
"@
    }
}

# Function to get system time
function Get-SystemTime {
    <#
    .SYNOPSIS
        Gets the current local system time using Win32 API.
    .DESCRIPTION
        Retrieves the current local time via GetLocalTime.
    .EXAMPLE
        Get-SystemTime
    .OUTPUTS
        DateTime object representing current local time.
    #>
    param()
    
    Initialize-Win32API
    $sysTime = New-Object Win32API+SYSTEMTIME
    [Win32API]::GetLocalTime([ref]$sysTime) | Out-Null
    
    return [DateTime]::new(
        $sysTime.wYear, $sysTime.wMonth, $sysTime.wDay,
        $sysTime.wHour, $sysTime.wMinute, $sysTime.wSecond, $sysTime.wMilliseconds
    )
}

# Function to set system time
function Set-SystemTime {
    <#
    .SYNOPSIS
        Sets the local system time using Win32 API.
    .DESCRIPTION
        Updates the local system time via SetLocalTime.
    .PARAMETER DateTime
        The DateTime object to set.
    .EXAMPLE
        Set-SystemTime -DateTime (Get-Date)
    .OUTPUTS
        Boolean indicating success or failure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [DateTime]$DateTime
    )
    
    Initialize-Win32API
    $sysTime = New-Object Win32API+SYSTEMTIME
    $sysTime.wYear = $DateTime.Year
    $sysTime.wMonth = $DateTime.Month
    $sysTime.wDay = $DateTime.Day
    $sysTime.wHour = $DateTime.Hour
    $sysTime.wMinute = $DateTime.Minute
    $sysTime.wSecond = $DateTime.Second
    $sysTime.wMilliseconds = $DateTime.Millisecond
    
    return [Win32API]::SetLocalTime([ref]$sysTime)
}

# Function to send message timeout
function Send-MessageTimeout {
    <#
    .SYNOPSIS
        Sends a message with timeout using Win32 API.
    .DESCRIPTION
        Uses SendMessageTimeout to send a message to a window.
    .PARAMETER HWnd
        Window handle to send message to.
    .PARAMETER Message
        The message ID to send.
    .PARAMETER Timeout
        Timeout in milliseconds (default: 5000).
    .EXAMPLE
        Send-MessageTimeout -HWnd 0xffff -Message 0x001A -Timeout 5000
    .OUTPUTS
        IntPtr result from the message.
    #>
    param(
        [IntPtr]$HWnd,
        [uint]$Message,
        [uint]$Timeout = 5000
    )
    
    Initialize-Win32API
    $result = [IntPtr]::Zero
    [Win32API]::SendMessageTimeout($HWnd, $Message, [IntPtr]::Zero, [IntPtr]::Zero, 0, $Timeout, [ref]$result) | Out-Null
    return $result
}

# Function to broadcast settings change
function Invoke-BroadcastSettingsChange {
    <#
    .SYNOPSIS
        Broadcasts a settings change notification to all windows.
    .DESCRIPTION
        Sends WM_SETTINGCHANGE message to notify applications of settings changes.
    .EXAMPLE
        Invoke-BroadcastSettingsChange
    .OUTPUTS
        None. Broadcasts the message.
    #>
    param()
    
    $result = Send-MessageTimeout -HWnd 0xffff -Message 0x001A -Timeout 5000
    return $result -ne [IntPtr]::Zero
}

# Function to initialize NONCLIENTMETRICS structure
function Initialize-NonClientMetrics {
    <#
    .SYNOPSIS
        Initializes the NONCLIENTMETRICS structure.
    .DESCRIPTION
        Creates the NONCLIENTMETRICS struct type if not already defined.
    .EXAMPLE
        Initialize-NonClientMetrics
    .OUTPUTS
        None. Creates the type definition.
    #>
    param()
    
    if (-not ([System.Management.Automation.PSTypeName]'NONCLIENTMETRICS').Type) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct NONCLIENTMETRICS {
    public uint cbSize;
    public int iBorderWidth;
    public int iScrollWidth;
    public int iScrollHeight;
    public int iCaptionWidth;
    public int iCaptionHeight;
    public LOGFONT lfCaptionFont;
    public int iSmCaptionWidth;
    public int iSmCaptionHeight;
    public LOGFONT lfSmCaptionFont;
    public int iMenuWidth;
    public int iMenuHeight;
    public LOGFONT lfMenuFont;
    public LOGFONT lfStatusFont;
    public LOGFONT lfMessageFont;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public struct LOGFONT {
    public int lfHeight;
    public int lfWidth;
    public int lfEscapement;
    public int lfOrientation;
    public int lfWeight;
    public byte lfItalic;
    public byte lfUnderline;
    public byte lfStrikeOut;
    public byte lfCharSet;
    public byte lfOutPrecision;
    public byte lfClipPrecision;
    public byte lfQuality;
    public byte lfPitchAndFamily;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string lfFaceName;
}
"@
    }
}

# Export the module members
Export-ModuleMember -Function Initialize-AnimationInfo, Set-AnimationInfo, Initialize-Win32API, Get-SystemTime, Set-SystemTime, Send-MessageTimeout, Invoke-BroadcastSettingsChange, Initialize-NonClientMetrics -Verbose:$false
