<#
.SYNOPSIS
    Windows utility functions for administrative tasks and common operations.
.DESCRIPTION
    Provides functions for checking administrative privileges, elevation, and various system utilities.
.NOTES
    File Name      : WindowsUtils.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Function to check if running with administrative privileges
function Test-AdminRights {
    <#
    .SYNOPSIS
        Checks if the current PowerShell session has administrative privileges.
    .DESCRIPTION
        Returns $true if running with admin rights, $false otherwise.
    .EXAMPLE
        if (Test-AdminRights) { Write-Host "Running as Administrator" }
    .OUTPUTS
        System.Boolean
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to elevate the current script if not running as admin
function Request-Elevation {
    <#
    .SYNOPSIS
        Prompts for elevation if not running as administrator.
    .DESCRIPTION
        Restarts the current script with elevated privileges if needed.
        Includes error handling to prevent auto-closing on failure.
    .EXAMPLE
        Request-Elevation
    #>
    if (-not (Test-AdminRights)) {
        Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
        
        # Create a temporary script to run elevated with error handling
        $scriptPath = $MyInvocation.MyCommand.Path
        $errorScript = @"
param(`$OriginalScript = '$scriptPath')
try {
    & "`$OriginalScript"
    if (`$LASTEXITCODE -ne 0) {
        Write-Host "Script failed with exit code: `$LASTEXITCODE" -ForegroundColor Red
        Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
        Read-Host
    }
} catch {
    Write-Host "ERROR: `$(`$_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: `$(`$_.ScriptStackTrace)" -ForegroundColor DarkRed
    Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
    Read-Host
}
"@
        
        $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
        $errorScript | Out-File -FilePath $tempScript -Encoding UTF8
        
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`" -OriginalScript `"$scriptPath`"" -Verb RunAs
        exit
    }
}

# Function to get system information
function Get-SystemInfo {
    <#
    .SYNOPSIS
        Retrieves basic system information.
    .DESCRIPTION
        Returns an object containing system name, OS version, and architecture.
    .EXAMPLE
        $info = Get-SystemInfo
        Write-Host "Running on $($info.ComputerName) with $($info.OSVersion)"
    .OUTPUTS
        PSCustomObject
    #>
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem
    
    return [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        OSVersion    = $os.Caption
        Architecture = $os.OSArchitecture
        TotalMemory  = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        BootupState  = $computer.BootupState
    }
}

# Function to get current user information
function Get-CurrentUserInfo {
    <#
    .SYNOPSIS
        Gets information about the current logged-in user.
    .DESCRIPTION
        Returns user name, domain, and privilege level.
    .EXAMPLE
        $user = Get-CurrentUserInfo
        Write-Host "Logged in as $($user.Username) with $($user.PrivilegeLevel) privileges"
    .OUTPUTS
        PSCustomObject
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    
    return [PSCustomObject]@{
        Username      = $env:USERNAME
        Domain        = $env:USERDOMAIN
        IsAdmin       = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        PrivilegeLevel = if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { "Administrator" } else { "Standard User" }
    }
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
        if (Test-ServiceExists -ServiceName "Spooler") { Write-Host "Print Spooler exists" }
    .OUTPUTS
        System.Boolean
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    return ($null -ne $service)
}

# Function to restart a service safely
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
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )
    
    if (-not (Test-ServiceExists -ServiceName $ServiceName)) {
        Write-Warning "Service '$ServiceName' does not exist"
        return
    }
    
    try {
        Write-Host "Restarting service '$ServiceName'..." -ForegroundColor Cyan
        Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "Service '$ServiceName' restarted successfully" -ForegroundColor Green
    }
    catch {
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
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName,
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
        Write-Host "Process '$ProcessName' has exited" -ForegroundColor Green
    }
}

# Export the module members
Export-ModuleMember -Function Test-AdminRights, Request-Elevation, Get-SystemInfo, Get-CurrentUserInfo, Test-ServiceExists, Restart-ServiceSafely, Wait-ProcessExit