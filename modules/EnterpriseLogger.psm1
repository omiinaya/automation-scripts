<#
.SYNOPSIS
    Enterprise-grade logging module for production automation systems.
.DESCRIPTION
    Provides structured logging with different log levels, audit trail capabilities,
    error recovery mechanisms, and compliance tracking for enterprise deployment.
.NOTES
    File Name      : EnterpriseLogger.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Version        : 1.0.0

.EXAMPLE
    Add-EnterpriseLog -Level "INFO" -Message "Script execution started" -Category "Audit"
.EXAMPLE
    Add-EnterpriseLog -Level "ERROR" -Message "Registry access denied" -Category "Security" -Exception $_.Exception
#>

# Log configuration
$Script:LogConfiguration = @{
    LogLevels = @("DEBUG", "INFO", "WARN", "ERROR", "FATAL")
    DefaultLogLevel = "INFO"
    LogFormat = "JSON"  # JSON, CSV, TEXT
    EnableConsoleOutput = $true
    EnableFileOutput = $true
    EnableEventLogOutput = $false
    MaxLogFileSizeMB = 10
    LogRetentionDays = 30
    LogPath = "$PSScriptRoot\..\logs"
    ApplicationName = "CISAutomation"
}

# Log level priorities
$Script:LogLevelPriorities = @{
    "DEBUG" = 1
    "INFO" = 2
    "WARN" = 3
    "ERROR" = 4
    "FATAL" = 5
}

# Function to initialize logging system
function Initialize-EnterpriseLogging {
    <#
    .SYNOPSIS
        Initializes the enterprise logging system.
    .DESCRIPTION
        Sets up logging directories, validates configuration, and prepares the logging environment.
    .PARAMETER LogPath
        Custom log directory path.
    .PARAMETER ApplicationName
        Application name for log identification.
    .PARAMETER LogLevel
        Minimum log level to record.
    .EXAMPLE
        Initialize-EnterpriseLogging -LogPath "C:\Logs\CIS" -ApplicationName "CISCompliance" -LogLevel "INFO"
    .OUTPUTS
        Boolean indicating initialization success.
    #>
    param(
        [string]$LogPath,
        [string]$ApplicationName,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$LogLevel
    )

    try {
        # Update configuration if parameters provided
        if ($LogPath) { $Script:LogConfiguration.LogPath = $LogPath }
        if ($ApplicationName) { $Script:LogConfiguration.ApplicationName = $ApplicationName }
        if ($LogLevel) { $Script:LogConfiguration.DefaultLogLevel = $LogLevel }

        # Create log directory
        if (-not (Test-Path $Script:LogConfiguration.LogPath)) {
            New-Item -ItemType Directory -Path $Script:LogConfiguration.LogPath -Force | Out-Null
            Write-Verbose "Created log directory: $($Script:LogConfiguration.LogPath)"
        }

        # Validate log directory
        if (-not (Test-Path $Script:LogConfiguration.LogPath)) {
            Write-Error "Failed to create or access log directory: $($Script:LogConfiguration.LogPath)"
            return $false
        }

        # Test write permissions
        $testFile = Join-Path $Script:LogConfiguration.LogPath "permission-test.txt"
        try {
            "Permission test" | Out-File -FilePath $testFile -Force
            Remove-Item $testFile -Force
        } catch {
            Write-Error "Insufficient permissions to write to log directory: $($Script:LogConfiguration.LogPath)"
            return $false
        }

        # Initialize audit trail
        Initialize-AuditTrail

        Write-Verbose "Enterprise logging system initialized successfully"
        return $true

    } catch {
        Write-Error "Failed to initialize enterprise logging system: $_"
        return $false
    }
}

# Function to add structured log entries
function Add-EnterpriseLog {
    <#
    .SYNOPSIS
        Adds a structured log entry with comprehensive metadata.
    .DESCRIPTION
        Creates detailed log entries with timestamps, correlation IDs, user context,
        and optional exception information for enterprise-level logging.
    .PARAMETER Level
        Log level (DEBUG, INFO, WARN, ERROR, FATAL).
    .PARAMETER Message
        Log message text.
    .PARAMETER Category
        Log category for filtering (Audit, Security, Performance, System, Application).
    .PARAMETER Exception
        Exception object for error logging.
    .PARAMETER CorrelationId
        Correlation ID for tracing requests across systems.
    .PARAMETER AdditionalData
        Additional structured data for the log entry.
    .PARAMETER ScriptName
        Name of the script generating the log.
    .PARAMETER FunctionName
        Name of the function generating the log.
    .EXAMPLE
        Add-EnterpriseLog -Level "INFO" -Message "Audit script executed" -Category "Audit"
    .EXAMPLE
        Add-EnterpriseLog -Level "ERROR" -Message "Registry access failed" -Category "Security" -Exception $_.Exception
    .OUTPUTS
        Log entry object with metadata.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet("Audit", "Security", "Performance", "System", "Application")]
        [string]$Category = "Application",

        [System.Exception]$Exception,

        [string]$CorrelationId,

        [hashtable]$AdditionalData,

        [string]$ScriptName,

        [string]$FunctionName
    )

    try {
        # Check if logging is enabled for this level
        $currentLevelPriority = $Script:LogLevelPriorities[$Level]
        $configuredLevelPriority = $Script:LogLevelPriorities[$Script:LogConfiguration.DefaultLogLevel]

        if ($currentLevelPriority -lt $configuredLevelPriority) {
            return $null
        }

        # Generate correlation ID if not provided
        if (-not $CorrelationId) {
            $CorrelationId = New-CorrelationId
        }

        # Get script and function names if not provided
        if (-not $ScriptName) {
            $ScriptName = (Get-PSCallStack)[1].ScriptName
        }
        if (-not $FunctionName) {
            $FunctionName = (Get-PSCallStack)[1].FunctionName
        }

        # Create log entry object
        $logEntry = [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            Level = $Level
            Message = $Message
            Category = $Category
            ScriptName = $ScriptName
            FunctionName = $FunctionName
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            ProcessId = $PID
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            CorrelationId = $CorrelationId
            ExceptionType = if ($Exception) { $Exception.GetType().Name } else { $null }
            ExceptionMessage = if ($Exception) { $Exception.Message } else { $null }
            StackTrace = if ($Exception) { $Exception.StackTrace } else { $null }
            AdditionalData = if ($AdditionalData) { $AdditionalData | ConvertTo-Json -Compress } else { $null }
        }

        # Write to configured outputs
        Write-LogToOutputs -LogEntry $logEntry

        return $logEntry

    } catch {
        Write-Warning "Failed to add enterprise log entry: $_"
        return $null
    }
}

# Function to write log entry to all configured outputs
function Write-LogToOutputs {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$LogEntry
    )

    try {
        # Console output
        if ($Script:LogConfiguration.EnableConsoleOutput) {
            Write-LogToConsole -LogEntry $LogEntry
        }

        # File output
        if ($Script:LogConfiguration.EnableFileOutput) {
            Write-LogToFile -LogEntry $LogEntry
        }

        # Event log output
        if ($Script:LogConfiguration.EnableEventLogOutput) {
            Write-LogToEventLog -LogEntry $LogEntry
        }

    } catch {
        Write-Warning "Failed to write log to outputs: $_"
    }
}

# Function to write log entry to console
function Write-LogToConsole {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$LogEntry
    )

    $color = switch ($LogEntry.Level) {
        "DEBUG" { "Gray" }
        "INFO" { "White" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "FATAL" { "DarkRed" }
        default { "White" }
    }

    $message = "[$($LogEntry.Timestamp)] [$($LogEntry.Level)] [$($LogEntry.Category)] $($LogEntry.Message)"
    if ($LogEntry.ExceptionMessage) {
        $message += " - Exception: $($LogEntry.ExceptionMessage)"
    }

    Write-Host $message -ForegroundColor $color
}

# Function to write log entry to file
function Write-LogToFile {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$LogEntry
    )

    try {
        # Determine log file path based on format
        $logFileName = "$($Script:LogConfiguration.ApplicationName)_$(Get-Date -Format 'yyyy-MM-dd').log"
        $logFilePath = Join-Path $Script:LogConfiguration.LogPath $logFileName

        # Rotate log file if it exceeds size limit
        if (Test-Path $logFilePath) {
            $fileInfo = Get-Item $logFilePath
            if ($fileInfo.Length -gt ($Script:LogConfiguration.MaxLogFileSizeMB * 1MB)) {
                Rotate-LogFile -FilePath $logFilePath
            }
        }

        # Format log entry based on configured format
        $logLine = Format-LogEntry -LogEntry $LogEntry

        # Append to log file
        $logLine | Out-File -FilePath $logFilePath -Append -Encoding UTF8

    } catch {
        Write-Warning "Failed to write log to file: $_"
    }
}

# Function to format log entry based on configuration
function Format-LogEntry {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$LogEntry
    )

    switch ($Script:LogConfiguration.LogFormat) {
        "JSON" {
            return $LogEntry | ConvertTo-Json -Compress
        }
        "CSV" {
            $properties = $LogEntry.PSObject.Properties.Name
            $values = $properties | ForEach-Object { $LogEntry.$_ }
            return ($values -join ",")
        }
        "TEXT" {
            return "[$($LogEntry.Timestamp)] [$($LogEntry.Level)] [$($LogEntry.Category)] $($LogEntry.Message)"
        }
        default {
            return $LogEntry | ConvertTo-Json -Compress
        }
    }
}

# Function to rotate log files
function Rotate-LogFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    try {
        $directory = Split-Path $FilePath -Parent
        $fileName = Split-Path $FilePath -Leaf
        $baseName = $fileName -replace '\.\w+$', ''
        $extension = [System.IO.Path]::GetExtension($fileName)

        # Find the next available rotation number
        $rotationNumber = 1
        $newFileName = "${baseName}_${rotationNumber}${extension}"
        $newFilePath = Join-Path $directory $newFileName

        while (Test-Path $newFilePath) {
            $rotationNumber++
            $newFileName = "${baseName}_${rotationNumber}${extension}"
            $newFilePath = Join-Path $directory $newFileName
        }

        # Rename the current file
        Rename-Item -Path $FilePath -NewName $newFileName

        Write-Verbose "Rotated log file: $FilePath -> $newFilePath"

    } catch {
        Write-Warning "Failed to rotate log file: $_"
    }
}

# Function to generate correlation ID
function New-CorrelationId {
    <#
    .SYNOPSIS
        Generates a unique correlation ID for request tracing.
    .DESCRIPTION
        Creates a GUID-based correlation ID with timestamp encoding for distributed tracing.
    .EXAMPLE
        $correlationId = New-CorrelationId
    .OUTPUTS
        String containing the correlation ID.
    #>
    return [System.Guid]::NewGuid().ToString()
}

# Function to initialize audit trail
function Initialize-AuditTrail {
    <#
    .SYNOPSIS
        Initializes the audit trail system for compliance tracking.
    .DESCRIPTION
        Sets up audit trail logging for security and compliance requirements.
    #>
    try {
        $auditTrailPath = Join-Path $Script:LogConfiguration.LogPath "audit-trail"
        if (-not (Test-Path $auditTrailPath)) {
            New-Item -ItemType Directory -Path $auditTrailPath -Force | Out-Null
        }

        # Create audit trail header if file doesn't exist
        $auditTrailFile = Join-Path $auditTrailPath "audit-trail.csv"
        if (-not (Test-Path $auditTrailFile)) {
            $header = "Timestamp,EventType,User,Computer,CIS_ID,Action,Result,Details"
            $header | Out-File -FilePath $auditTrailFile -Encoding UTF8
        }

        Write-Verbose "Audit trail system initialized"

    } catch {
        Write-Warning "Failed to initialize audit trail: $_"
    }
}

# Function to add audit trail entry
function Add-AuditTrailEntry {
    <#
    .SYNOPSIS
        Adds an entry to the audit trail for compliance tracking.
    .DESCRIPTION
        Records security-relevant actions for compliance and forensic analysis.
    .PARAMETER EventType
        Type of audit event (SecurityChange, ConfigurationChange, AccessAttempt, Error).
    .PARAMETER Action
        Description of the action performed.
    .PARAMETER Result
        Result of the action (Success, Failure, Partial).
    .PARAMETER CIS_ID
        CIS benchmark ID if applicable.
    .PARAMETER Details
        Additional details about the event.
    .EXAMPLE
        Add-AuditTrailEntry -EventType "SecurityChange" -Action "Disabled service" -Result "Success" -CIS_ID "2.3.1.1"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("SecurityChange", "ConfigurationChange", "AccessAttempt", "Error", "SystemEvent")]
        [string]$EventType,

        [Parameter(Mandatory=$true)]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Success", "Failure", "Partial")]
        [string]$Result,

        [string]$CIS_ID,

        [string]$Details
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $user = $env:USERNAME
        $computer = $env:COMPUTERNAME

        $auditEntry = "$timestamp,$EventType,$user,$computer,$CIS_ID,$Action,$Result,$Details"

        $auditTrailPath = Join-Path $Script:LogConfiguration.LogPath "audit-trail"
        $auditTrailFile = Join-Path $auditTrailPath "audit-trail.csv"

        $auditEntry | Out-File -FilePath $auditTrailFile -Append -Encoding UTF8

        # Also log as security event
        Add-EnterpriseLog -Level "INFO" -Message "Audit trail: $Action" -Category "Security" -AdditionalData @{
            EventType = $EventType
            Result = $Result
            CIS_ID = $CIS_ID
            Details = $Details
        }

    } catch {
        Write-Warning "Failed to add audit trail entry: $_"
    }
}

# Function to get log statistics
function Get-LogStatistics {
    <#
    .SYNOPSIS
        Retrieves statistics about the logging system.
    .DESCRIPTION
        Provides insights into log volume, distribution by level, and system health.
    .EXAMPLE
        $stats = Get-LogStatistics
    .OUTPUTS
        Hashtable containing log statistics.
    #>

    try {
        $stats = @{
            TotalLogFiles = 0
            TotalLogEntries = 0
            LogLevelDistribution = @{}
            DiskUsageMB = 0
            OldestLogDate = $null
            NewestLogDate = $null
        }

        # Count log files
        if (Test-Path $Script:LogConfiguration.LogPath) {
            $logFiles = Get-ChildItem -Path $Script:LogConfiguration.LogPath -Filter "*.log" -File
            $stats.TotalLogFiles = $logFiles.Count

            # Calculate disk usage
            $stats.DiskUsageMB = [math]::Round(($logFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

            # Get date range
            if ($logFiles.Count -gt 0) {
                $stats.OldestLogDate = ($logFiles | Sort-Object LastWriteTime)[0].LastWriteTime
                $stats.NewestLogDate = ($logFiles | Sort-Object LastWriteTime -Descending)[0].LastWriteTime
            }
        }

        return $stats

    } catch {
        Write-Warning "Failed to get log statistics: $_"
        return @{}
    }
}

# Function to configure logging
function Set-LogConfiguration {
    <#
    .SYNOPSIS
        Configures the enterprise logging system.
    .DESCRIPTION
        Allows runtime configuration of logging parameters.
    .PARAMETER LogLevel
        Minimum log level to record.
    .PARAMETER LogFormat
        Output format (JSON, CSV, TEXT).
    .PARAMETER EnableConsoleOutput
        Enable console logging.
    .PARAMETER EnableFileOutput
        Enable file logging.
    .PARAMETER MaxLogFileSizeMB
        Maximum log file size in MB.
    .EXAMPLE
        Set-LogConfiguration -LogLevel "WARN" -LogFormat "JSON"
    #>
    param(
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$LogLevel,

        [ValidateSet("JSON", "CSV", "TEXT")]
        [string]$LogFormat,

        [bool]$EnableConsoleOutput,

        [bool]$EnableFileOutput,

        [int]$MaxLogFileSizeMB
    )

    if ($LogLevel) { $Script:LogConfiguration.DefaultLogLevel = $LogLevel }
    if ($LogFormat) { $Script:LogConfiguration.LogFormat = $LogFormat }
    if ($PSBoundParameters.ContainsKey("EnableConsoleOutput")) { 
        $Script:LogConfiguration.EnableConsoleOutput = $EnableConsoleOutput }
    if ($PSBoundParameters.ContainsKey("EnableFileOutput")) { 
        $Script:LogConfiguration.EnableFileOutput = $EnableFileOutput }
    if ($MaxLogFileSizeMB) { $Script:LogConfiguration.MaxLogFileSizeMB = $MaxLogFileSizeMB }

    Write-Verbose "Log configuration updated"
}

# Function to clean up old log files
function Clear-OldLogs {
    <#
    .SYNOPSIS
        Cleans up old log files based on retention policy.
    .DESCRIPTION
        Removes log files older than the configured retention period.
    .PARAMETER RetentionDays
        Number of days to retain logs (overrides configuration).
    .EXAMPLE
        Clear-OldLogs -RetentionDays 7
    .OUTPUTS
        Number of files removed.
    #>
    param(
        [int]$RetentionDays
    )

    try {
        if (-not $RetentionDays) {
            $RetentionDays = $Script:LogConfiguration.LogRetentionDays
        }

        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $logFiles = Get-ChildItem -Path $Script:LogConfiguration.LogPath -Filter "*.log" -File
        $oldFiles = $logFiles | Where-Object { $_.LastWriteTime -lt $cutoffDate }

        $removedCount = 0
        foreach ($file in $oldFiles) {
            try {
                Remove-Item $file.FullName -Force
                $removedCount++
                Write-Verbose "Removed old log file: $($file.Name)"
            } catch {
                Write-Warning "Failed to remove log file $($file.Name): $_"
            }
        }

        return $removedCount

    } catch {
        Write-Warning "Failed to clear old logs: $_"
        return 0
    }
}

# Export the module members
Export-ModuleMember -Function Initialize-EnterpriseLogging, Add-EnterpriseLog, Add-AuditTrailEntry, Get-LogStatistics, Set-LogConfiguration, Clear-OldLogs, New-CorrelationId -Verbose:$false

# Initialize logging when module is imported
Initialize-EnterpriseLogging

Write-Verbose "EnterpriseLogger module loaded successfully"
