<#
Audit Batch Execution Script
Purpose: Execute all PowerShell audit scripts under windows/security/audits and store outputs in individual log files

Requirements:
- Create logs directory structure that mirrors the audit script structure
- Execute each PowerShell audit script sequentially
- Capture both stdout and stderr outputs for each script
- Save each audit output to a corresponding log file with timestamp
- Include error handling to continue execution even if some scripts fail
- Provide progress reporting during execution
- Generate a summary report at the end

Features:
- Creates logs directory: windows/security/audit-logs/
- Mirrors the section folder structure in the logs directory
- Each log file named: [script-name]-[timestamp].log
- Includes execution timestamp, script path, and execution status
- Handles PowerShell execution policy restrictions
- Continues execution even if individual scripts fail
#>

[CmdletBinding()]
param(
    [switch]$ForceExecutionPolicy,
    [string]$LogsBasePath = "windows/security/logs",
    [string]$AuditsBasePath = "windows/security/audits"
)

# Set script execution variables
$Script:ExecutionStartTime = Get-Date
$Script:TotalScriptsProcessed = 0
$Script:SuccessfulScripts = 0
$Script:FailedScripts = 0
$Script:SkippedScripts = 0
$Script:ExecutionResults = @()

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to create directory structure
function New-LogDirectoryStructure {
    param(
        [string]$AuditPath,
        [string]$LogPath
    )
    
    try {
        # Resolve audit path to absolute path
        $absoluteAuditPath = Resolve-Path $AuditPath -ErrorAction Stop
        
        # Ensure log base directory exists before resolving
        if (-not (Test-Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        $absoluteLogPath = Resolve-Path $LogPath -ErrorAction Stop
        
        # Get all directory paths from audit structure
        $directories = Get-ChildItem -Path $absoluteAuditPath -Recurse -Directory |
            Select-Object -ExpandProperty FullName
        
        # Create corresponding log directories
        foreach ($dir in $directories) {
            $relativePath = $dir.Replace($absoluteAuditPath.Path, "").TrimStart('\')
            $logDir = Join-Path $absoluteLogPath.Path $relativePath
            
            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
                Write-Verbose "Created log directory: $logDir"
            }
        }
        
        Write-ColorOutput "[SUCCESS] Log directory structure created successfully" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "[FAILED] Failed to create log directory structure: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to discover audit scripts
function Get-AuditScripts {
    param(
        [string]$AuditPath
    )
    
    try {
        $scripts = Get-ChildItem -Path $AuditPath -Recurse -File -Filter "*.ps1" | 
            Where-Object { $_.Name -like "*-audit-*" }
        
        Write-ColorOutput "[SUCCESS] Discovered $($scripts.Count) audit scripts" "Green"
        return $scripts
    }
    catch {
        Write-ColorOutput "[FAILED] Failed to discover audit scripts: $($_.Exception.Message)" "Red"
        return @()
    }
}

# Function to execute single audit script
function Invoke-AuditScript {
    param(
        [System.IO.FileInfo]$ScriptFile,
        [string]$LogsBasePath,
        [string]$AuditsBasePath
    )
    
    $scriptName = $ScriptFile.BaseName
    $scriptPath = $ScriptFile.FullName
    
    # Resolve base paths to absolute paths
    $absoluteAuditsBasePath = Resolve-Path $AuditsBasePath -ErrorAction Stop
    
    # Ensure log base directory exists before resolving
    if (-not (Test-Path $LogsBasePath)) {
        New-Item -ItemType Directory -Path $LogsBasePath -Force | Out-Null
    }
    $absoluteLogsBasePath = Resolve-Path $LogsBasePath -ErrorAction Stop
    
    $relativePath = $scriptPath.Replace($absoluteAuditsBasePath.Path, "").TrimStart('\')
    $logRelativePath = [System.IO.Path]::GetDirectoryName($relativePath)
    
    # Create log file path using proper path concatenation
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFileName = "$scriptName-$timestamp.log"
    $logDirPath = Join-Path $absoluteLogsBasePath.Path $logRelativePath
    $logFilePath = Join-Path $logDirPath $logFileName
    
    # Ensure log directory exists
    $logDir = [System.IO.Path]::GetDirectoryName($logFilePath)
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Create execution result object
    $result = [PSCustomObject]@{
        ScriptName = $scriptName
        ScriptPath = $relativePath
        LogFilePath = $logFilePath
        StartTime = Get-Date
        EndTime = $null
        Success = $false
        ExitCode = $null
        ErrorMessage = $null
        Output = $null
    }
    
    Write-ColorOutput "[EXECUTING] $relativePath" "Yellow"
    
    try {
        # Start transcript for capturing all output
        Start-Transcript -Path $logFilePath -Append | Out-Null
        
        Write-Host "=== AUDIT SCRIPT EXECUTION ==="
        Write-Host "Script: $relativePath"
        Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "Log File: $logFilePath"
        Write-Host ""
        
        # Execute the script directly to capture all output streams
        $scriptOutput = & $scriptPath -Verbose 2>&1
        
        # Capture the boolean result separately
        $scriptResult = $?
        
        # Convert all output to string format for logging
        $outputText = $scriptOutput | Out-String
        
        # Check if script executed successfully
        if ($scriptResult -eq $true) {
            $result.Success = $true
            $result.ExitCode = 0
            Write-Host "[SUCCESS] Script completed successfully" -ForegroundColor Green
        } else {
            $result.Success = $false
            $result.ExitCode = 1
            $result.ErrorMessage = "Script execution failed"
            Write-Host "[FAILED] Script execution failed" -ForegroundColor Red
        }
        
        $result.Output = $outputText
        
    }
    catch {
        $result.Success = $false
        $result.ExitCode = 1
        $result.ErrorMessage = $_.Exception.Message
        Write-Host "[ERROR] Script execution error: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # Stop transcript
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Transcript might already be stopped
        }
        
        $result.EndTime = Get-Date
        Write-Host ""
        Write-Host "Execution Time: $($result.EndTime - $result.StartTime)"
        Write-Host "Status: $(if ($result.Success) { 'SUCCESS' } else { 'FAILED' })"
        Write-Host "=== END OF EXECUTION ==="
        Write-Host ""
    }
    
    return $result
}

# Function to generate summary report
function Write-SummaryReport {
    param(
        [array]$Results,
        [datetime]$StartTime
    )
    
    $endTime = Get-Date
    $totalDuration = $endTime - $StartTime
    
    Write-Host ""
    Write-Host "=== AUDIT BATCH EXECUTION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Start Time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "End Time: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Total Duration: $totalDuration"
    Write-Host ""
    Write-Host "Script Statistics:" -ForegroundColor White
    Write-Host "  Total Scripts: $($Results.Count)" -ForegroundColor Gray
    Write-Host "  Successful: $($Results | Where-Object { $_.Success }).Count" -ForegroundColor Green
    Write-Host "  Failed: $($Results | Where-Object { -not $_.Success }).Count" -ForegroundColor Red
    Write-Host ""
    
    # Failed scripts details
    $failedScripts = $Results | Where-Object { -not $_.Success }
    if ($failedScripts.Count -gt 0) {
        Write-Host "Failed Scripts:" -ForegroundColor Red
        foreach ($failed in $failedScripts) {
            Write-Host "  - $($failed.ScriptPath)" -ForegroundColor Yellow
            if ($failed.ErrorMessage) {
                Write-Host "    Error: $($failed.ErrorMessage.Trim())" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Log files location
    Write-Host "Log Files Location:" -ForegroundColor White
    Write-Host "  Base Directory: $LogsBasePath" -ForegroundColor Gray
    Write-Host ""
    
    # Overall status
    $successRate = [math]::Round(($Results | Where-Object { $_.Success }).Count / $Results.Count * 100, 2)
    if ($successRate -ge 90) {
        Write-Host "[EXCELLENT] Overall Status: EXCELLENT ($successRate% success rate)" -ForegroundColor Green
    }
    elseif ($successRate -ge 70) {
        Write-Host "[GOOD] Overall Status: GOOD ($successRate% success rate)" -ForegroundColor Yellow
    }
    else {
        Write-Host "[POOR] Overall Status: POOR ($successRate% success rate)" -ForegroundColor Red
    }
}

# Main execution function
function Start-AuditBatchExecution {
    param(
        [string]$AuditsBasePath,
        [string]$LogsBasePath,
        [switch]$ForceExecutionPolicy
    )
    
    Write-Host "=== AUDIT BATCH EXECUTION STARTED ===" -ForegroundColor Cyan
    Write-Host "Audit Scripts Path: $AuditsBasePath"
    Write-Host "Logs Output Path: $LogsBasePath"
    Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    
    # Handle execution policy if requested
    if ($ForceExecutionPolicy) {
        try {
            $currentPolicy = Get-ExecutionPolicy
            Write-ColorOutput "Current execution policy: $currentPolicy" "Yellow"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
            Write-ColorOutput "Execution policy set to RemoteSigned for this session" "Green"
        }
        catch {
            Write-ColorOutput "Warning: Could not change execution policy: $($_.Exception.Message)" "Yellow"
        }
    }
    
    # Verify audit scripts path exists
    if (-not (Test-Path $AuditsBasePath)) {
        Write-ColorOutput "[FAILED] Audit scripts path not found: $AuditsBasePath" "Red"
        return
    }
    
    # Create logs directory structure
    Write-ColorOutput "Creating log directory structure..." "White"
    $structureCreated = New-LogDirectoryStructure -AuditPath $AuditsBasePath -LogPath $LogsBasePath
    
    if (-not $structureCreated) {
        Write-ColorOutput "[FAILED] Cannot proceed without log directory structure" "Red"
        return
    }
    
    # Discover audit scripts
    Write-ColorOutput "Discovering audit scripts..." "White"
    $auditScripts = Get-AuditScripts -AuditPath $AuditsBasePath
    
    if ($auditScripts.Count -eq 0) {
        Write-ColorOutput "[FAILED] No audit scripts found" "Red"
        return
    }
    
    Write-Host ""
    Write-ColorOutput "Starting sequential execution of $($auditScripts.Count) audit scripts..." "Cyan"
    Write-Host ""
    
    # Execute scripts sequentially
    $executionResults = @()
    $scriptCounter = 0
    
    foreach ($script in $auditScripts) {
        $scriptCounter++
        Write-ColorOutput "[$scriptCounter/$($auditScripts.Count)] " -NoNewline
        
        $result = Invoke-AuditScript -ScriptFile $script -LogsBasePath $LogsBasePath -AuditsBasePath $AuditsBasePath
        $executionResults += $result
        
        # Update counters
        if ($result.Success) {
            $Script:SuccessfulScripts++
            Write-ColorOutput "[SUCCESS] Completed successfully" "Green"
        } else {
            $Script:FailedScripts++
            Write-ColorOutput "[FAILED] Execution failed" "Red"
        }
        
        $Script:TotalScriptsProcessed++
        Write-Host ""
    }
    
    # Generate summary report
    Write-SummaryReport -Results $executionResults -StartTime $Script:ExecutionStartTime
    
    # Store results
    $Script:ExecutionResults = $executionResults
}

# Execute the batch process
Start-AuditBatchExecution -AuditsBasePath $AuditsBasePath -LogsBasePath $LogsBasePath -ForceExecutionPolicy:$ForceExecutionPolicy

# Return execution statistics
return @{
    TotalScripts = $Script:TotalScriptsProcessed
    SuccessfulScripts = $Script:SuccessfulScripts
    FailedScripts = $Script:FailedScripts
    SkippedScripts = $Script:SkippedScripts
    ExecutionStartTime = $Script:ExecutionStartTime
    ExecutionEndTime = Get-Date
}