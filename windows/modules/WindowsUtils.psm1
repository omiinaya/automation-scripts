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
        
        # Get the current script path
        $scriptPath = $MyInvocation.ScriptName
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }
        
        # Create a proper temporary script for elevation
        $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
        
        # Build the script content with comprehensive error handling
        $scriptContent = @"
# Elevation wrapper script with comprehensive error handling
param(
    [string]`$TargetScript = '$($scriptPath -replace "'", "''")'
)

# Initialize error tracking
`$hasError = `$false
`$errorMessages = [System.Collections.ArrayList]::new()
`$originalErrorAction = `$ErrorActionPreference

# Function to capture and display errors
function Write-ErrorLog {
    param(
        [string]`$Message,
        [string]`$Severity = "ERROR"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "`$timestamp [`$Severity] `$Message"
    
    # Add to error collection
    [void]`$errorMessages.Add(`$logEntry)
    
    # Write to console with appropriate colors
    switch (`$Severity) {
        "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
        "INFO" { Write-Host `$logEntry -ForegroundColor Cyan }
        default { Write-Host `$logEntry }
    }
}

# Function to capture all error streams
function Invoke-ScriptWithErrorCapture {
    param(
        [string]`$ScriptPath
    )
    
    try {
        # Create temporary files for error capturing
        `$errorFile = [System.IO.Path]::GetTempFileName()
        `$outputFile = [System.IO.Path]::GetTempFileName()
        
        # Build the command with proper error stream redirection
        `$psCommand = "powershell.exe"
        `$psArgs = "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"`$ScriptPath`""
        
        Write-ErrorLog -Message "Starting elevated execution: `$ScriptPath" -Severity "INFO"
        
        # Execute the process with redirected streams
        `$processInfo = New-Object System.Diagnostics.ProcessStartInfo
        `$processInfo.FileName = `$psCommand
        `$processInfo.Arguments = `$psArgs -join " "
        `$processInfo.RedirectStandardError = `$true
        `$processInfo.RedirectStandardOutput = `$true
        `$processInfo.UseShellExecute = `$false
        `$processInfo.CreateNoWindow = `$true
        
        `$process = New-Object System.Diagnostics.Process
        `$process.StartInfo = `$processInfo
        `$process.Start() | Out-Null
        
        # Read all output and error streams
        `$stdout = `$process.StandardOutput.ReadToEnd()
        `$stderr = `$process.StandardError.ReadToEnd()
        
        `$process.WaitForExit()
        `$exitCode = `$process.ExitCode
        
        # Process captured streams
        if (-not [string]::IsNullOrEmpty(`$stdout)) {
            Write-Host `$stdout
        }
        
        if (-not [string]::IsNullOrEmpty(`$stderr)) {
            `$stderr -split "`r`n" | ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace(`$_)) {
                    Write-ErrorLog -Message `$_ -Severity "ERROR"
                }
            }
        }
        
        # Clean up temporary files
        Remove-Item `$errorFile -ErrorAction SilentlyContinue
        Remove-Item `$outputFile -ErrorAction SilentlyContinue
        
        return @{
            ExitCode = `$exitCode
            StdOut = `$stdout
            StdErr = `$stderr
            HasErrors = `$exitCode -ne 0 -or -not [string]::IsNullOrEmpty(`$stderr)
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to execute script: `$(`$_.Exception.Message)" -Severity "ERROR"
        Write-ErrorLog -Message "Stack Trace: `$(`$_.ScriptStackTrace)" -Severity "ERROR"
        return @{
            ExitCode = 1
            StdOut = ""
            StdErr = `$.Exception.Message
            HasErrors = `$true
        }
    }
}

try {
    # Set strict error handling
    `$ErrorActionPreference = 'Stop'
    
    if (Test-Path `$TargetScript) {
        # Execute script with comprehensive error capture
        `$result = Invoke-ScriptWithErrorCapture -ScriptPath `$TargetScript
        
        if (`$result.HasErrors) {
            `$hasError = `$true
            Write-ErrorLog -Message "Script completed with errors (Exit Code: `$(`$result.ExitCode))" -Severity "ERROR"
        }
        else {
            Write-ErrorLog -Message "Script completed successfully (Exit Code: `$(`$result.ExitCode))" -Severity "INFO"
        }
    }
    else {
        `$hasError = `$true
        Write-ErrorLog -Message "Target script not found: `$TargetScript" -Severity "ERROR"
    }
}
catch {
    `$hasError = `$true
    Write-ErrorLog -Message "Unexpected error during execution: `$(`$_.Exception.Message)" -Severity "ERROR"
    Write-ErrorLog -Message "Stack Trace: `$(`$_.ScriptStackTrace)" -Severity "ERROR"
}
finally {
    # Restore original error action preference
    `$ErrorActionPreference = `$originalErrorAction
    
    # Display summary of all errors
    if (`$errorMessages.Count -gt 0) {
        Write-Host "`n=== ERROR SUMMARY ===" -ForegroundColor Red
        `$errorMessages | ForEach-Object { Write-Host `$_ -ForegroundColor Red }
        Write-Host "===================" -ForegroundColor Red
    }
    
    # Only wait for user input if there were actual errors
    if (`$hasError) {
        Write-Host "`n" -NoNewline
        Write-Host "ERROR DETECTED - Press Enter to close this window..." -ForegroundColor Yellow -BackgroundColor DarkRed
        `$null = Read-Host
    }
    else {
        Write-Host "`nOperation completed successfully - closing in 2 seconds..." -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    
    # Exit with appropriate code
    exit (`$hasError ? 1 : 0)
}
"@
        
        # Write the script to temp file
        $scriptContent | Out-File -FilePath $tempScript -Encoding UTF8
        
        # Start the elevated process with proper argument formatting
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
        $psi.Verb = "runas"
        $psi.UseShellExecute = $true
        
        try {
            $process = [System.Diagnostics.Process]::Start($psi)
            exit
        } catch {
            Write-Host "ERROR: Failed to start elevated process. $_" -ForegroundColor Red
            Write-Host "You may need to manually run this script as Administrator." -ForegroundColor Yellow
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