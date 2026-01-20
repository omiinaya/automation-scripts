<#
.SYNOPSIS
    Enterprise health monitoring and performance tracking module.
.DESCRIPTION
    Provides script health monitoring, performance metrics tracking,
    automated validation checks, and system health assessment.
.NOTES
    File Name      : HealthMonitor.psm1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Version        : 1.0.0

.EXAMPLE
    $health = Get-SystemHealth -CheckType "Comprehensive"
.EXAMPLE
    $metrics = Get-PerformanceMetrics -DurationSeconds 60
#>

# Import required modules
Import-Module "$PSScriptRoot\EnterpriseLogger.psm1" -Force -WarningAction SilentlyContinue

# Health monitoring configuration
$Script:HealthConfiguration = @{
    CheckIntervals = @{
        Quick = 30      # seconds
        Standard = 300  # 5 minutes
        Comprehensive = 1800  # 30 minutes
    }
    PerformanceThresholds = @{
        CPUUsagePercent = 80
        MemoryUsagePercent = 85
        DiskUsagePercent = 90
        NetworkLatencyMs = 100
    }
    HealthStatusLevels = @{
        Healthy = 90    # 90-100%
        Warning = 70    # 70-89%
        Critical = 0    # 0-69%
    }
}

# Function to get comprehensive system health
function Get-SystemHealth {
    <#
    .SYNOPSIS
        Retrieves comprehensive system health information.
    .DESCRIPTION
        Performs multi-dimensional health assessment including performance,
        resource utilization, and service status.
    .PARAMETER CheckType
        Type of health check to perform.
    .EXAMPLE
        $health = Get-SystemHealth -CheckType "Comprehensive"
    .OUTPUTS
        System health assessment object.
    #>
    param(
        [ValidateSet("Quick", "Standard", "Comprehensive")]
        [string]$CheckType = "Standard"
    )

    try {
        $healthResults = @()
        $overallScore = 100

        # Performance metrics
        $performanceHealth = Get-PerformanceHealth
        $healthResults += $performanceHealth
        $overallScore = [math]::Min($overallScore, $performanceHealth.Score)

        # Resource utilization
        $resourceHealth = Get-ResourceHealth
        $healthResults += $resourceHealth
        $overallScore = [math]::Min($overallScore, $resourceHealth.Score)

        # Service status
        $serviceHealth = Get-ServiceHealth
        $healthResults += $serviceHealth
        $overallScore = [math]::Min($overallScore, $serviceHealth.Score)

        # Security health
        $securityHealth = Get-SecurityHealth
        $healthResults += $securityHealth
        $overallScore = [math]::Min($overallScore, $securityHealth.Score)

        # Determine overall health status
        $healthStatus = Get-HealthStatus -Score $overallScore

        Add-EnterpriseLog -Level "INFO" -Message "System health assessment completed" -Category "Monitoring" -AdditionalData @{
            CheckType = $CheckType
            OverallScore = $overallScore
            HealthStatus = $healthStatus
        }

        return [PSCustomObject]@{
            OverallScore = $overallScore
            HealthStatus = $healthStatus
            CheckType = $CheckType
            Results = $healthResults
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "System health assessment failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            OverallScore = 0
            HealthStatus = "Critical"
            CheckType = $CheckType
            Results = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
        }
    }
}

# Function to get performance health metrics
function Get-PerformanceHealth {
    try {
        $performanceChecks = @()
        $performanceScore = 100

        # CPU utilization
        $cpuUsage = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
        if ($cpuUsage) {
            $cpuPercent = [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)
            $isHealthy = $cpuPercent -le $Script:HealthConfiguration.PerformanceThresholds.CPUUsagePercent
            $performanceChecks += [PSCustomObject]@{
                Metric = "CPUUsage"
                Value = $cpuPercent
                Unit = "%"
                IsHealthy = $isHealthy
                Threshold = $Script:HealthConfiguration.PerformanceThresholds.CPUUsagePercent
            }
            if (-not $isHealthy) { $performanceScore = [math]::Min($performanceScore, 70) }
        }

        # Memory utilization
        $memory = Get-WmiObject Win32_OperatingSystem
        if ($memory) {
            $totalMemory = $memory.TotalVisibleMemorySize / 1KB
            $freeMemory = $memory.FreePhysicalMemory / 1KB
            $usedMemory = $totalMemory - $freeMemory
            $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
            $isHealthy = $memoryPercent -le $Script:HealthConfiguration.PerformanceThresholds.MemoryUsagePercent
            $performanceChecks += [PSCustomObject]@{
                Metric = "MemoryUsage"
                Value = $memoryPercent
                Unit = "%"
                IsHealthy = $isHealthy
                Threshold = $Script:HealthConfiguration.PerformanceThresholds.MemoryUsagePercent
            }
            if (-not $isHealthy) { $performanceScore = [math]::Min($performanceScore, 70) }
        }

        # Disk utilization
        $drive = Get-PSDrive -Name "C" -ErrorAction SilentlyContinue
        if ($drive) {
            $diskPercent = [math]::Round((($drive.Used / $drive.Used + $drive.Free)) * 100, 2)
            $isHealthy = $diskPercent -le $Script:HealthConfiguration.PerformanceThresholds.DiskUsagePercent
            $performanceChecks += [PSCustomObject]@{
                Metric = "DiskUsage"
                Value = $diskPercent
                Unit = "%"
                IsHealthy = $isHealthy
                Threshold = $Script:HealthConfiguration.PerformanceThresholds.DiskUsagePercent
            }
            if (-not $isHealthy) { $performanceScore = [math]::Min($performanceScore, 70) }
        }

        return [PSCustomObject]@{
            Category = "Performance"
            Score = $performanceScore
            Checks = $performanceChecks
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "WARN" -Message "Performance health check failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            Category = "Performance"
            Score = 0
            Checks = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to get resource health metrics
function Get-ResourceHealth {
    try {
        $resourceChecks = @()
        $resourceScore = 100

        # Available disk space
        $drive = Get-PSDrive -Name "C" -ErrorAction SilentlyContinue
        if ($drive) {
            $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
            $isHealthy = $freeSpaceGB -gt 5  # 5GB minimum
            $resourceChecks += [PSCustomObject]@{
                Metric = "FreeDiskSpace"
                Value = $freeSpaceGB
                Unit = "GB"
                IsHealthy = $isHealthy
                Threshold = 5
            }
            if (-not $isHealthy) { $resourceScore = [math]::Min($resourceScore, 50) }
        }

        # Available memory
        $memory = Get-WmiObject Win32_OperatingSystem
        if ($memory) {
            $freeMemoryMB = [math]::Round($memory.FreePhysicalMemory / 1KB, 2)
            $isHealthy = $freeMemoryMB -gt 512  # 512MB minimum
            $resourceChecks += [PSCustomObject]@{
                Metric = "FreeMemory"
                Value = $freeMemoryMB
                Unit = "MB"
                IsHealthy = $isHealthy
                Threshold = 512
            }
            if (-not $isHealthy) { $resourceScore = [math]::Min($resourceScore, 70) }
        }

        # Process count
        $processCount = (Get-Process).Count
        $isHealthy = $processCount -lt 200  # Reasonable process count
        $resourceChecks += [PSCustomObject]@{
            Metric = "ProcessCount"
            Value = $processCount
            Unit = "processes"
            IsHealthy = $isHealthy
            Threshold = 200
        }
        if (-not $isHealthy) { $resourceScore = [math]::Min($resourceScore, 80) }

        return [PSCustomObject]@{
            Category = "Resources"
            Score = $resourceScore
            Checks = $resourceChecks
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "WARN" -Message "Resource health check failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            Category = "Resources"
            Score = 0
            Checks = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to get service health status
function Get-ServiceHealth {
    try {
        $serviceChecks = @()
        $serviceScore = 100

        # Critical services to monitor
        $criticalServices = @(
            @{ Name = "Winmgmt"; DisplayName = "Windows Management Instrumentation" },
            @{ Name = "RpcSs"; DisplayName = "Remote Procedure Call" },
            @{ Name = "EventLog"; DisplayName = "Windows Event Log" },
            @{ Name = "CryptSvc"; DisplayName = "Cryptographic Services" }
        )

        foreach ($service in $criticalServices) {
            $serviceStatus = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($serviceStatus) {
                $isHealthy = $serviceStatus.Status -eq "Running"
                $serviceChecks += [PSCustomObject]@{
                    Metric = $service.Name
                    DisplayName = $service.DisplayName
                    Value = $serviceStatus.Status
                    IsHealthy = $isHealthy
                    Expected = "Running"
                }
                if (-not $isHealthy) { $serviceScore = [math]::Min($serviceScore, 60) }
            }
        }

        return [PSCustomObject]@{
            Category = "Services"
            Score = $serviceScore
            Checks = $serviceChecks
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "WARN" -Message "Service health check failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            Category = "Services"
            Score = 0
            Checks = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to get security health status
function Get-SecurityHealth {
    try {
        $securityChecks = @()
        $securityScore = 100

        # UAC status
        $uacStatus = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uacStatus) {
            $isHealthy = $uacStatus.EnableLUA -eq 1
            $securityChecks += [PSCustomObject]@{
                Metric = "UACEnabled"
                Value = if ($isHealthy) { "Enabled" } else { "Disabled" }
                IsHealthy = $isHealthy
                Expected = "Enabled"
            }
            if (-not $isHealthy) { $securityScore = [math]::Min($securityScore, 70) }
        }

        # Windows Defender status
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            $isHealthy = $defenderStatus.AntivirusEnabled
            $securityChecks += [PSCustomObject]@{
                Metric = "WindowsDefender"
                Value = if ($isHealthy) { "Enabled" } else { "Disabled" }
                IsHealthy = $isHealthy
                Expected = "Enabled"
            }
            if (-not $isHealthy) { $securityScore = [math]::Min($securityScore, 50) }
        }

        # Firewall status
        $firewallProfile = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        if ($firewallProfile) {
            $enabledProfiles = ($firewallProfile | Where-Object { $_.Enabled -eq 'True' }).Count
            $isHealthy = $enabledProfiles -gt 0
            $securityChecks += [PSCustomObject]@{
                Metric = "FirewallEnabled"
                Value = "$enabledProfiles profiles enabled"
                IsHealthy = $isHealthy
                Expected = "At least 1 profile enabled"
            }
            if (-not $isHealthy) { $securityScore = [math]::Min($securityScore, 60) }
        }

        return [PSCustomObject]@{
            Category = "Security"
            Score = $securityScore
            Checks = $securityChecks
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "WARN" -Message "Security health check failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            Category = "Security"
            Score = 0
            Checks = @()
            ErrorMessage = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to determine health status from score
function Get-HealthStatus {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Score
    )

    if ($Score -ge $Script:HealthConfiguration.HealthStatusLevels.Healthy) {
        return "Healthy"
    } elseif ($Score -ge $Script:HealthConfiguration.HealthStatusLevels.Warning) {
        return "Warning"
    } else {
        return "Critical"
    }
}

# Function to start continuous health monitoring
function Start-HealthMonitoring {
    <#
    .SYNOPSIS
        Starts continuous health monitoring with configurable intervals.
    .DESCRIPTION
        Runs health checks at specified intervals and logs results.
    .PARAMETER CheckType
        Type of health check to perform.
    .PARAMETER IntervalSeconds
        Monitoring interval in seconds.
    .PARAMETER DurationMinutes
        Total monitoring duration in minutes.
    .EXAMPLE
        Start-HealthMonitoring -CheckType "Standard" -IntervalSeconds 60 -DurationMinutes 30
    .OUTPUTS
        Monitoring session information.
    #>
    param(
        [ValidateSet("Quick", "Standard", "Comprehensive")]
        [string]$CheckType = "Standard",

        [int]$IntervalSeconds,

        [int]$DurationMinutes = 30
    )

    try {
        if (-not $IntervalSeconds) {
            $IntervalSeconds = $Script:HealthConfiguration.CheckIntervals[$CheckType]
        }

        Add-EnterpriseLog -Level "INFO" -Message "Starting health monitoring" -Category "Monitoring" -AdditionalData @{
            CheckType = $CheckType
            IntervalSeconds = $IntervalSeconds
            DurationMinutes = $DurationMinutes
        }

        $monitoringResults = @()
        $startTime = Get-Date
        $endTime = $startTime.AddMinutes($DurationMinutes)

        while ((Get-Date) -lt $endTime) {
            $healthResult = Get-SystemHealth -CheckType $CheckType
            $monitoringResults += $healthResult

            # Log critical issues immediately
            if ($healthResult.HealthStatus -eq "Critical") {
                Add-EnterpriseLog -Level "ERROR" -Message "Critical health issue detected" -Category "Monitoring" -AdditionalData @{
                    OverallScore = $healthResult.OverallScore
                    HealthStatus = $healthResult.HealthStatus
                }
            }

            # Wait for next interval
            Start-Sleep -Seconds $IntervalSeconds
        }

        # Generate monitoring summary
        $averageScore = if ($monitoringResults.Count -gt 0) {
            [math]::Round(($monitoringResults | Measure-Object -Property OverallScore -Average).Average, 2)
        } else { 0 }

        $criticalCount = ($monitoringResults | Where-Object { $_.HealthStatus -eq "Critical" }).Count
        $warningCount = ($monitoringResults | Where-Object { $_.HealthStatus -eq "Warning" }).Count

        Add-EnterpriseLog -Level "INFO" -Message "Health monitoring completed" -Category "Monitoring" -AdditionalData @{
            TotalChecks = $monitoringResults.Count
            AverageScore = $averageScore
            CriticalCount = $criticalCount
            WarningCount = $warningCount
        }

        return [PSCustomObject]@{
            MonitoringSession = [PSCustomObject]@{
                StartTime = $startTime
                EndTime = Get-Date
                DurationMinutes = $DurationMinutes
                IntervalSeconds = $IntervalSeconds
                TotalChecks = $monitoringResults.Count
            }
            Summary = [PSCustomObject]@{
                AverageScore = $averageScore
                CriticalCount = $criticalCount
                WarningCount = $warningCount
                HealthyCount = $monitoringResults.Count - $criticalCount - $warningCount
            }
            Results = $monitoringResults
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Health monitoring failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            MonitoringSession = [PSCustomObject]@{
                StartTime = $startTime
                EndTime = Get-Date
                Error = $_.Exception.Message
            }
            Summary = [PSCustomObject]@{
                AverageScore = 0
                CriticalCount = 0
                WarningCount = 0
                HealthyCount = 0
            }
            Results = @()
        }
    }
}

# Function to get performance metrics over time
function Get-PerformanceMetrics {
    <#
    .SYNOPSIS
        Collects performance metrics over a specified duration.
    .DESCRIPTION
        Gathers detailed performance data for trend analysis and capacity planning.
    .PARAMETER DurationSeconds
        Duration to collect metrics in seconds.
    .PARAMETER SampleInterval
        Interval between samples in seconds.
    .EXAMPLE
        $metrics = Get-PerformanceMetrics -DurationSeconds 60 -SampleInterval 5
    .OUTPUTS
        Performance metrics collection.
    #>
    param(
        [int]$DurationSeconds = 60,

        [int]$SampleInterval = 5
    )

    try {
        $metrics = @()
        $sampleCount = [math]::Ceiling($DurationSeconds / $SampleInterval)

        Add-EnterpriseLog -Level "INFO" -Message "Starting performance metrics collection" -Category "Monitoring" -AdditionalData @{
            DurationSeconds = $DurationSeconds
            SampleInterval = $SampleInterval
            SampleCount = $sampleCount
        }

        for ($i = 0; $i -lt $sampleCount; $i++) {
            $timestamp = Get-Date
            
            # Collect metrics
            $cpuUsage = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            $memory = Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue
            $drive = Get-PSDrive -Name "C" -ErrorAction SilentlyContinue

            $metric = [PSCustomObject]@{
                Timestamp = $timestamp
                SampleNumber = $i + 1
            }

            if ($cpuUsage) {
                $metric | Add-Member -NotePropertyName "CPUUsagePercent" -NotePropertyValue [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)
            }

            if ($memory) {
                $totalMemory = $memory.TotalVisibleMemorySize / 1KB
                $freeMemory = $memory.FreePhysicalMemory / 1KB
                $usedMemory = $totalMemory - $freeMemory
                $metric | Add-Member -NotePropertyName "MemoryUsagePercent" -NotePropertyValue [math]::Round(($usedMemory / $totalMemory) * 100, 2)
                $metric | Add-Member -NotePropertyName "FreeMemoryMB" -NotePropertyValue [math]::Round($freeMemory, 2)
            }

            if ($drive) {
                $metric | Add-Member -NotePropertyName "DiskUsagePercent" -NotePropertyValue [math]::Round((($drive.Used / ($drive.Used + $drive.Free)) * 100), 2)
                $metric | Add-Member -NotePropertyName "FreeDiskSpaceGB" -NotePropertyValue [math]::Round($drive.Free / 1GB, 2)
            }

            $metrics += $metric
            
            if ($i -lt $sampleCount - 1) {
                Start-Sleep -Seconds $SampleInterval
            }
        }

        # Calculate averages
        $averageCPU = if ($metrics.CPUUsagePercent) { [math]::Round(($metrics.CPUUsagePercent | Measure-Object -Average).Average, 2) } else { 0 }
        $averageMemory = if ($metrics.MemoryUsagePercent) { [math]::Round(($metrics.MemoryUsagePercent | Measure-Object -Average).Average, 2) } else { 0 }

        Add-EnterpriseLog -Level "INFO" -Message "Performance metrics collection completed" -Category "Monitoring" -AdditionalData @{
            AverageCPU = $averageCPU
            AverageMemory = $averageMemory
            TotalSamples = $metrics.Count
        }

        return [PSCustomObject]@{
            Metrics = $metrics
            Summary = [PSCustomObject]@{
                AverageCPUUsagePercent = $averageCPU
                AverageMemoryUsagePercent = $averageMemory
                TotalSamples = $metrics.Count
                DurationSeconds = $DurationSeconds
            }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Performance metrics collection failed" -Category "Monitoring" -Exception $_
        return [PSCustomObject]@{
            Metrics = @()
            Summary = [PSCustomObject]@{
                AverageCPUUsagePercent = 0
                AverageMemoryUsagePercent = 0
                TotalSamples = 0
                Error = $_.Exception.Message
            }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Function to create health alert
function New-HealthAlert {
    <#
    .SYNOPSIS
        Creates health alerts for critical system conditions.
    .DESCRIPTION
        Generates structured alerts for monitoring and notification systems.
    .PARAMETER AlertType
        Type of alert to create.
    .PARAMETER Severity
        Alert severity level.
    .PARAMETER Message
        Alert message.
    .PARAMETER Metric
        Metric that triggered the alert.
    .PARAMETER Threshold
        Threshold value.
    .PARAMETER CurrentValue
        Current metric value.
    .EXAMPLE
        New-HealthAlert -AlertType "Performance" -Severity "High" -Message "CPU usage critical" -Metric "CPUUsage" -Threshold 90 -CurrentValue 95
    .OUTPUTS
        Health alert object.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Performance", "Resource", "Service", "Security")]
        [string]$AlertType,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Severity,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$Metric,

        [object]$Threshold,

        [object]$CurrentValue
    )

    try {
        $alert = [PSCustomObject]@{
            AlertType = $AlertType
            Severity = $Severity
            Message = $Message
            Metric = $Metric
            Threshold = $Threshold
            CurrentValue = $CurrentValue
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            AlertId = [System.Guid]::NewGuid().ToString()
        }

        # Log the alert
        Add-EnterpriseLog -Level "WARN" -Message "Health alert generated" -Category "Monitoring" -AdditionalData @{
            AlertType = $AlertType
            Severity = $Severity
            Message = $Message
            Metric = $Metric
        }

        return $alert

    } catch {
        Add-EnterpriseLog -Level "ERROR" -Message "Failed to create health alert" -Category "Monitoring" -Exception $_
        return $null
    }
}

# Export the module members
Export-ModuleMember -Function Get-SystemHealth, Start-HealthMonitoring, Get-PerformanceMetrics, New-HealthAlert -Verbose:$false

Write-Verbose "HealthMonitor module loaded successfully"