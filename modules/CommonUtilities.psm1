<#
.SYNOPSIS
    Common utility functions for PowerShell automation scripts.
.DESCRIPTION
    Provides standardized functions for error handling, admin rights checking, service management,
    and other common operations to eliminate code duplication across modules.
.NOTES
    File Name      : CommonUtilities.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    
.EXAMPLE
    Wait-OnError -ErrorMessage "Operation failed" -Troubleshooting "Check permissions"
.EXAMPLE
    if (Test-AdminRights) { Write-StatusMessage -Message "Running as Administrator" -Type Info }
.EXAMPLE
    if (Test-ServiceExists -ServiceName "Spooler") { Write-StatusMessage -Message "Print Spooler exists" -Type Info }
#>

# Function to pause on error with standardized error handling
function Wait-OnError {
    <#
    .SYNOPSIS
        Standardized error handling function with pause and troubleshooting support.
    .DESCRIPTION
        Displays error messages with consistent formatting, provides troubleshooting steps,
        and waits for user input before exiting.
    .PARAMETER ErrorMessage
        The error message to display.
    .PARAMETER Troubleshooting
        Optional troubleshooting steps to display.
    .PARAMETER ExitCode
        Optional exit code to use when exiting (default: 1).
    .EXAMPLE
        Wait-OnError -ErrorMessage "Failed to modify registry" -Troubleshooting "Run as Administrator"
    .EXAMPLE
        Wait-OnError -ErrorMessage "Service not found" -ExitCode 2
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage,
        [string]$Troubleshooting = "",
        [int]$ExitCode = 1
    )
    
    Write-StatusMessage -Message "`nERROR: $ErrorMessage" -Type Error
    
    if ($Troubleshooting) {
        Write-StatusMessage -Message "`nTroubleshooting steps:" -Type Warning
        Write-Host $Troubleshooting -ForegroundColor Yellow
    }
    
    Write-StatusMessage -Message "`nPress Enter to close this window..." -Type Warning
    Read-Host
    
    exit $ExitCode
}

# Function to check if running with administrative privileges
function Test-AdminRights {
    <#
    .SYNOPSIS
        Checks if the current PowerShell session has administrative privileges.
    .DESCRIPTION
        Returns $true if running with admin rights, $false otherwise.
    .EXAMPLE
        if (Test-AdminRights) { Write-StatusMessage -Message "Running as Administrator" -Type Info }
    .OUTPUTS
        System.Boolean
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to test if a service exists
function Test-ServiceExists {
    <#
    .SYNOPSIS
        Checks if a Windows service exists.
    .DESCRIPTION
        Returns $true if the service exists, $false otherwise.
    .PARAMETER ServiceName
        The name of the service to check.
    .EXAMPLE
        if (Test-ServiceExists -ServiceName "Spooler") { Write-StatusMessage -Message "Print Spooler exists" -Type Info }
    .EXAMPLE
        $services = @("Spooler", "W32Time", "BITS") | Where-Object { Test-ServiceExists -ServiceName $_ }
    .OUTPUTS
        System.Boolean
    .NOTES
        Case-insensitive service name matching.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    return ($null -ne $service)
}

# Function to handle common errors with structured error information
function Handle-CommonError {
    <#
    .SYNOPSIS
        Standardized error handling function for common error patterns.
    .DESCRIPTION
        Provides structured error classification, logging with timestamps,
        and context-aware error recommendations.
    .PARAMETER ErrorRecord
        The PowerShell error record to handle.
    .PARAMETER Context
        Additional context information about where the error occurred.
    .PARAMETER ServiceName
        Service name related to the error.
    .PARAMETER RegistryPath
        Registry path related to the error.
    .EXAMPLE
        try {
            # Some operation
        } catch {
            $errorInfo = Handle-CommonError -ErrorRecord $_ -Context "Registry modification" -RegistryPath "HKLM:\SOFTWARE\Microsoft"
            Write-Error $errorInfo.ErrorMessage
        }
    .OUTPUTS
        PSCustomObject containing structured error information.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$Context = "Unknown",
        [string]$ServiceName,
        [string]$RegistryPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMessage = $ErrorRecord.Exception.Message
    
    # Error classification logic
    $errorType = "Unknown"
    $recommendation = "Check the error details and try again."
    
    # Classify errors based on common patterns
    switch -Wildcard ($errorMessage) {
        "*Access denied*" {
            $errorType = "PermissionError"
            $recommendation = "Run the script as administrator or check user permissions."
        }
        "*Cannot find path*" {
            $errorType = "PathNotFoundError"
            $recommendation = "Verify the file or registry path exists."
        }
        "*Service was not found*" {
            $errorType = "ServiceNotFoundError"
            $recommendation = "The specified service may not exist on this Windows version."
        }
        "*Registry key does not exist*" {
            $errorType = "RegistryKeyNotFoundError"
            $recommendation = "The registry key may not exist or may require administrator access."
        }
        "*Group Policy*" {
            $errorType = "GroupPolicyError"
            $recommendation = "This may require domain administrator privileges."
        }
        "*The RPC server is unavailable*" {
            $errorType = "RPCError"
            $recommendation = "Check if the RPC service is running and accessible."
        }
        "*Timeout*" {
            $errorType = "TimeoutError"
            $recommendation = "The operation timed out. Try again or increase timeout settings."
        }
        "*Insufficient system resources*" {
            $errorType = "ResourceError"
            $recommendation = "Check system resources and try again."
        }
    }
    
    # Context-specific recommendations
    switch ($Context) {
        "Registry" {
            if ($errorType -eq "Unknown") {
                $recommendation = "Check registry permissions and ensure the key exists."
            }
        }
        "Service" {
            if ($errorType -eq "Unknown") {
                $recommendation = "Verify service dependencies and ensure service exists on this system."
            }
        }
        "File" {
            if ($errorType -eq "Unknown") {
                $recommendation = "Check file permissions and ensure the file exists."
            }
        }
    }
    
    # Structured error information
    return [PSCustomObject]@{
        ErrorType = $errorType
        ErrorMessage = $errorMessage
        Recommendation = $recommendation
        Timestamp = $timestamp
        Context = $Context
        ServiceName = $ServiceName
        RegistryPath = $RegistryPath
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}

# Function to get module path resolution
function Get-ModulePath {
    <#
    .SYNOPSIS
        Gets the path to the modules directory.
    .DESCRIPTION
        Returns the absolute path to the modules directory for consistent module imports.
    .PARAMETER RelativePath
        Optional relative path to append to the modules directory.
    .EXAMPLE
        $modulePath = Get-ModulePath
        Import-Module "$modulePath\WindowsUtils.psm1"
    .EXAMPLE
        $modulePath = Get-ModulePath -RelativePath "WindowsUtils.psm1"
    .OUTPUTS
        System.String
    #>
    param(
        [string]$RelativePath = ""
    )
    
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $modulesPath = Join-Path $moduleRoot "modules"
    
    if ($RelativePath) {
        return Join-Path $modulesPath $RelativePath
    }
    
    return $modulesPath
}

# Function to validate script requirements
function Test-ScriptRequirements {
    <#
    .SYNOPSIS
        Validates common script requirements.
    .DESCRIPTION
        Checks Windows version, admin rights, and other common requirements.
    .PARAMETER MinWindowsVersion
        Minimum Windows version required (e.g., "10.0.22000" for Windows 11).
    .PARAMETER RequireAdmin
        Whether admin rights are required (default: $true).
    .PARAMETER RequireWindows11
        Whether Windows 11 is required.
    .EXAMPLE
        if (Test-ScriptRequirements -MinWindowsVersion "10.0.22000" -RequireAdmin $true) {
            # Proceed with script
        }
    .OUTPUTS
        System.Boolean
    #>
    param(
        [string]$MinWindowsVersion,
        [bool]$RequireAdmin = $true,
        [bool]$RequireWindows11 = $false
    )
    
    # Check admin rights
    if ($RequireAdmin -and -not (Test-AdminRights)) {
        Write-StatusMessage -Message "ERROR: Administrator privileges are required for this script." -Type Error
        Write-StatusMessage -Message "Please run PowerShell as Administrator." -Type Warning
        return $false
    }
    
    # Check Windows version
    if ($MinWindowsVersion -or $RequireWindows11) {
        try {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $currentVersion = [version]$os.Version
            
            if ($MinWindowsVersion) {
                $minVersion = [version]$MinWindowsVersion
                if ($currentVersion -lt $minVersion) {
                    Write-StatusMessage -Message "ERROR: This script requires Windows version $MinWindowsVersion or higher." -Type Error
                    Write-StatusMessage -Message "Current version: $($os.Caption)" -Type Warning
                    return $false
                }
            }
            
            if ($RequireWindows11) {
                # Windows 11 version is 10.0.22000 or higher
                if (-not ($currentVersion.Major -eq 10 -and $currentVersion.Minor -eq 0 -and $currentVersion.Build -ge 22000)) {
                    Write-StatusMessage -Message "ERROR: This script requires Windows 11." -Type Error
                    Write-StatusMessage -Message "Current version: $($os.Caption)" -Type Warning
                    return $false
                }
            }
        } catch {
            Write-StatusMessage -Message "WARNING: Could not determine Windows version: $_" -Type Warning
        }
    }
    
    return $true
}

# Function to safely restart a service
function Restart-ServiceSafely {
    <#
    .SYNOPSIS
        Restarts a Windows service with error handling.
    .DESCRIPTION
        Attempts to restart a service and provides feedback on success/failure.
    .PARAMETER ServiceName
        The name of the service to restart.
    .EXAMPLE
        Restart-ServiceSafely -ServiceName "Spooler"
    .EXAMPLE
        Restart-ServiceSafely -ServiceName "W32Time"
    .OUTPUTS
        None. Writes status messages to console.
    .NOTES
        Requires administrative privileges for service management.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceName
    )
    
    if (-not (Test-ServiceExists -ServiceName $ServiceName)) {
        Write-Warning "Service '$ServiceName' does not exist"
        return
    }
    
    try {
        Write-StatusMessage -Message "Restarting service '$ServiceName'..." -Type Info
        Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-StatusMessage -Message "Service '$ServiceName' restarted successfully" -Type Success
    } catch {
        Write-Error "Failed to restart service '$ServiceName': $_"
    }
}

# Function to wait for a process to exit
function Wait-ProcessExit {
    <#
    .SYNOPSIS
        Waits for a process to exit.
    .DESCRIPTION
        Monitors a process and waits until it terminates.
    .PARAMETER ProcessName
        The name of the process to wait for.
    .PARAMETER TimeoutSeconds
        Maximum time to wait in seconds (default: 30).
    .EXAMPLE
        Wait-ProcessExit -ProcessName "notepad" -TimeoutSeconds 10
    .EXAMPLE
        Wait-ProcessExit -ProcessName "chrome" -TimeoutSeconds 60
    .OUTPUTS
        None. Writes status messages to console.
    .NOTES
        Process name should not include .exe extension.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProcessName,
        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 30
    )
    
    $startTime = Get-Date
    while ((Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 1
    }
    
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Warning "Process '$ProcessName' did not exit within $TimeoutSeconds seconds"
    } else {
        Write-StatusMessage -Message "Process '$ProcessName' has exited" -Type Success
    }
}

# Function to import a module quietly (suppressing verbose output)
function Import-ModuleQuiet {
<#
.SYNOPSIS
Imports a PowerShell module with verbose output suppressed.
.DESCRIPTION
Temporarily suppresses verbose output during module import to keep the console clean.
.PARAMETER Path
The path to the module to import.
.PARAMETER Force
Whether to force import even if already loaded.
.EXAMPLE
Import-ModuleQuiet -Path ".\modules\WindowsUtils.psm1"
Import-ModuleQuiet -Path "$PSScriptRoot\CommonUtilities.psm1" -Force
.OUTPUTS
None. Imports the module.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$Force
)

$originalVerbosePreference = $VerbosePreference
$originalWarningPreference = $WarningPreference
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

try {
    if ($Force) {
        Import-Module $Path -Force -ErrorAction Stop
    } else {
        Import-Module $Path -ErrorAction Stop
    }
} finally {
    $VerbosePreference = $originalVerbosePreference
    $WarningPreference = $originalWarningPreference
}
}

# Function to write status messages that can be captured or suppressed
function Write-StatusMessage {
<#
.SYNOPSIS
Writes a status message with optional color coding.
.DESCRIPTION
Writes messages to the information stream (not the host) so they can be captured,
piped, or suppressed. Use -Host switch to force Write-Host behavior for interactive scripts.
.PARAMETER Message
The message to display.
.PARAMETER Type
The type of message: Info, Success, Warning, or Error.
.PARAMETER Host
Switch to use Write-Host instead of Write-Information (for interactive scripts).
.EXAMPLE
Write-StatusMessage -Message "Operation complete" -Type Success
Write-StatusMessage -Message "Warning: file not found" -Type Warning
Write-StatusMessage -Message "Error occurred" -Type Error -Host
.OUTPUTS
None. Writes to information stream or host.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [ValidateSet("Info", "Success", "Warning", "Error")]
    [string]$Type = "Info",
    [switch]$Host
)

$prefix = switch ($Type) {
    "Success" { "[SUCCESS]" }
    "Warning" { "[WARNING]" }
    "Error" { "[ERROR]" }
    default { "[INFO]" }
}

$fullMessage = "$prefix $Message"

if ($Host) {
    # Use Write-Host only when explicitly requested
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Microsoft.PowerShell.Utility\Write-Host $fullMessage -ForegroundColor $color
} else {
    # Default: Write to Information stream (can be captured, piped, or suppressed)
    Microsoft.PowerShell.Utility\Write-Information $fullMessage -InformationAction Continue
}
}

# Export the module members
Export-ModuleMember -Function Wait-OnError, Test-AdminRights, Test-ServiceExists, Handle-CommonError, Get-ModulePath, Test-ScriptRequirements, Restart-ServiceSafely, Wait-ProcessExit, Import-ModuleQuiet, Write-StatusMessage -Verbose:$false