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
function Invoke-Elevation {
    <#
    .SYNOPSIS
        Prompts for elevation if not running as administrator.
    .DESCRIPTION
        Restarts the current script with elevated privileges if needed.
        Preserves working directory and command line arguments.
        Captures the output of the elevated script and returns it.
    .EXAMPLE
        Invoke-Elevation
    #>
    if (-not (Test-AdminRights)) {
        Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
        
        # Get the current script path - try multiple methods for reliability
        $scriptPath = $MyInvocation.ScriptName
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $PSCommandPath
        }
        
        # Validate we have a valid script path
        if ([string]::IsNullOrEmpty($scriptPath) -or -not (Test-Path $scriptPath)) {
            Write-Host "ERROR: Could not determine script path for elevation." -ForegroundColor Red
            Write-Host "Current working directory: $(Get-Location)" -ForegroundColor Yellow
            Write-Host "Please run this script manually as Administrator." -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Script path identified: $scriptPath" -ForegroundColor Cyan
        
        # Get the current working directory to preserve context
        $currentDirectory = Get-Location
        
        # Get original command line arguments
        $originalArgs = if ($MyInvocation.UnboundArguments) { $MyInvocation.UnboundArguments -join " " } else { "" }
        
        # Create a temporary file to store the output of the elevated script
        $resultFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "elevated_result_$(Get-Date -Format 'yyyyMMddHHmmss').txt")
        
        # Build the command to execute the original script with proper context and capture output
        $command = @"
# Simple elevation wrapper that preserves context and captures output
Set-Location '$currentDirectory'
try {
    # Run the original script and capture its output
    `$output = & '$scriptPath' $originalArgs
    # Write the output to the result file
    `$output | Out-File -FilePath '$resultFile' -Encoding UTF8
    `$exitCode = `$LASTEXITCODE
    if (`$exitCode -ne 0 -and `$exitCode -ne `$null -and `$exitCode -ne '') {
        # Non-zero exit code indicates error; write error to result file
        "ExitCode:`$exitCode" | Out-File -FilePath '$resultFile' -Encoding UTF8 -Append
    }
} catch {
    # Write error to result file
    `$_.Exception.Message | Out-File -FilePath '$resultFile' -Encoding UTF8
}
"@
        
        # Create a simple temporary script
        $tempScript = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "elevated_$(Get-Date -Format 'yyyyMMddHHmmss').ps1")
        
        try {
            # Write the simple wrapper script
            $command | Out-File -FilePath $tempScript -Encoding UTF8
            
            Write-Host "Launching elevated PowerShell..." -ForegroundColor Green
            
            # Start the elevated process directly with the original script
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powershell.exe"
            $psi.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
            $psi.Verb = "runas"  # This triggers UAC elevation
            $psi.UseShellExecute = $true
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $psi.WorkingDirectory = $currentDirectory
            
            # Start the elevated process and wait for it to exit
            $process = [System.Diagnostics.Process]::Start($psi)
            if ($process -eq $null) {
                Write-Host "ERROR: Failed to start elevated process." -ForegroundColor Red
                exit 1
            }
            $process.WaitForExit()
            
            # Read the result file if it exists
            if (Test-Path $resultFile) {
                $result = Get-Content $resultFile -Raw
                # Trim whitespace and convert to boolean if possible
                if ($null -eq $result) {
                    $trimmed = ''
                } else {
                    $trimmed = $result.Trim()
                }
                # Try to convert to boolean (handles "True"/"False" strings)
                if ($trimmed -eq "True" -or $trimmed -eq "False") {
                    [bool]::Parse($trimmed)
                } else {
                    # If not a boolean string, output as-is
                    $trimmed
                }
            } else {
                Write-Host "ERROR: Elevated script did not produce a result file." -ForegroundColor Red
                exit 1
            }
            
            # Clean up temporary files
            Remove-Item $tempScript -ErrorAction SilentlyContinue
            Remove-Item $resultFile -ErrorAction SilentlyContinue
            
            # Exit the script with the result as output (the script will exit after this function returns)
            # The caller should capture this output.
            exit
        }
        catch {
            Write-Host "ERROR: Failed to request elevation: $_" -ForegroundColor Red
            Write-Host "Please manually run this script as Administrator." -ForegroundColor Yellow
            
            # Clean up temp file if it exists
            if (Test-Path $tempScript) {
                Remove-Item $tempScript -ErrorAction SilentlyContinue
            }
            if (Test-Path $resultFile) {
                Remove-Item $resultFile -ErrorAction SilentlyContinue
            }
            exit 1
        }
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
        Write-Host "Process '$ProcessName' has exited" -ForegroundColor Green
    }
}

# Export the module members
Export-ModuleMember -Function Test-AdminRights, Invoke-Elevation, Get-SystemInfo, Get-CurrentUserInfo, Test-ServiceExists, Restart-ServiceSafely, Wait-ProcessExit -Verbose:$false