<#
.SYNOPSIS
    Production testing script for CIS Automation Framework.
.DESCRIPTION
    Executes comprehensive tests including unit, integration, system, 
    performance, and security tests for production validation.
.NOTES
    File Name      : test-production.ps1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
    Version        : 1.0.0

.EXAMPLE
    .\scripts\test-production.ps1 -TestType "Comprehensive" -IncludePerformance -IncludeSecurity
.EXAMPLE
    .\scripts\test-production.ps1 -TestType "Unit" -ModuleName "CISFramework"
#>

param(
    [ValidateSet("Unit", "Integration", "System", "Comprehensive")]
    [string]$TestType = "Comprehensive",

    [string]$ModuleName,

    [switch]$IncludePerformance,

    [switch]$IncludeSecurity,

    [switch]$Verbose
)

# Import required modules
Import-Module "$PSScriptRoot\..\modules\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue

# Initialize logging
Initialize-EnterpriseLogging -LogLevel "INFO" -ApplicationName "CISAutomationTest"

Add-EnterpriseLog -Level "INFO" -Message "Starting production testing" -Category "Testing" -AdditionalData @{
    TestType = $TestType
    ModuleName = $ModuleName
    IncludePerformance = $IncludePerformance
    IncludeSecurity = $IncludeSecurity
}

Add-AuditTrailEntry -EventType "SystemEvent" -Action "Production testing started" -Result "InProgress" -Details "Test Type: $TestType"

try {
    # Display test header
    Write-Host ""
    Write-SectionHeader -Title "Production Testing Suite"
    Write-Host "Test Type: $TestType" -ForegroundColor Cyan
    if ($ModuleName) { Write-Host "Module: $ModuleName" -ForegroundColor Cyan }
    Write-Host "Include Performance: $(if ($IncludePerformance) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
    Write-Host "Include Security: $(if ($IncludeSecurity) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
    Write-Host ""

    # System health check
    Write-StatusMessage -Message "Checking system health..." -Type Info
    $healthCheck = Get-SystemHealth -CheckType "Quick"
    Write-Host "  Overall Score: $($healthCheck.OverallScore)% ($($healthCheck.HealthStatus))" -ForegroundColor $(switch ($healthCheck.HealthStatus) { "Healthy" { "Green" } "Warning" { "Yellow" } "Critical" { "Red" } })

    # Execute test suite
    Write-StatusMessage -Message "Executing test suite..." -Type Info
    $testResults = Invoke-TestSuite -TestType $TestType -ModuleName $ModuleName -IncludePerformance:$IncludePerformance -IncludeSecurity:$IncludeSecurity

    # Display test results
    Write-Host ""
    Write-SectionHeader -Title "Test Results Summary"
    Write-Host "Overall Success: $(if ($testResults.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($testResults.OverallSuccess) { "Green" } else { "Red" })
    Write-Host "Test Type: $($testResults.TestType)" -ForegroundColor White
    if ($testResults.ModuleName) { Write-Host "Module: $($testResults.ModuleName)" -ForegroundColor White }
    Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
    Write-Host "Passed Tests: $($testResults.PassedTests)" -ForegroundColor Green
    Write-Host "Failed Tests: $($testResults.FailedTests)" -ForegroundColor $(if ($testResults.FailedTests -eq 0) { "Green" } else { "Red" })
    Write-Host "Success Rate: $($testResults.SuccessRate)%" -ForegroundColor $(if ($testResults.SuccessRate -ge 90) { "Green" } elseif ($testResults.SuccessRate -ge 70) { "Yellow" } else { "Red" })

    # Display detailed results by test type
    if ($testResults.TestResults) {
        Write-Host ""
        Write-Host "Detailed Results by Test Type:" -ForegroundColor Yellow
        foreach ($typeResult in $testResults.TestResults) {
            $statusColor = if ($typeResult.OverallSuccess) { "Green" } else { "Red" }
            Write-Host "  $($typeResult.TestType):" -ForegroundColor $statusColor
            Write-Host "    Total: $($typeResult.TotalTests)" -ForegroundColor White
            Write-Host "    Passed: $($typeResult.PassedTests)" -ForegroundColor Green
            Write-Host "    Failed: $($typeResult.FailedTests)" -ForegroundColor $(if ($typeResult.FailedTests -eq 0) { "Green" } else { "Red" })
            Write-Host "    Success: $(if ($typeResult.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor $statusColor
        }
    }

    # Display individual test failures
    $failedTests = $testResults.TestResults | Where-Object { $_.FailedTests -gt 0 }
    if ($failedTests) {
        Write-Host ""
        Write-Host "Failed Tests:" -ForegroundColor Red
        foreach ($failedType in $failedTests) {
            Write-Host "  $($failedType.TestType):" -ForegroundColor Red
            foreach ($testDetail in $failedType.TestDetails) {
                if ($testDetail.Result -eq "Fail") {
                    Write-Host "    $($testDetail.TestName): $($testDetail.Message)" -ForegroundColor Red
                    if ($testDetail.ErrorMessage) {
                        Write-Host "      Error: $($testDetail.ErrorMessage)" -ForegroundColor DarkRed
                    }
                }
            }
        }
    }

    # Performance metrics if included
    if ($IncludePerformance) {
        Write-Host ""
        Write-SectionHeader -Title "Performance Metrics"
        
        # Collect performance metrics
        Write-StatusMessage -Message "Collecting performance metrics..." -Type Info
        $performanceMetrics = Get-PerformanceMetrics -DurationSeconds 30 -SampleInterval 5
        
        Write-Host "  Average CPU Usage: $($performanceMetrics.Summary.AverageCPUUsagePercent)%" -ForegroundColor White
        Write-Host "  Average Memory Usage: $($performanceMetrics.Summary.AverageMemoryUsagePercent)%" -ForegroundColor White
        Write-Host "  Total Samples: $($performanceMetrics.Summary.TotalSamples)" -ForegroundColor White
        Write-Host "  Duration: $($performanceMetrics.Summary.DurationSeconds) seconds" -ForegroundColor White
    }

    # Security assessment if included
    if ($IncludeSecurity) {
        Write-Host ""
        Write-SectionHeader -Title "Security Assessment"
        
        Write-StatusMessage -Message "Performing security assessment..." -Type Info
        $securityAudit = Invoke-SecurityAudit -AuditType "Comprehensive"
        
        Write-Host "  Security Score: $($securityAudit.SecurityScore)%" -ForegroundColor $(if ($securityAudit.SecurityScore -ge 85) { "Green" } elseif ($securityAudit.SecurityScore -ge 70) { "Yellow" } else { "Red" })
        Write-Host "  Total Checks: $($securityAudit.TotalChecks)" -ForegroundColor White
        Write-Host "  Passed: $($securityAudit.PassCount)" -ForegroundColor Green
        Write-Host "  Failed: $($securityAudit.FailCount)" -ForegroundColor $(if ($securityAudit.FailCount -eq 0) { "Green" } else { "Red" })
    }

    # Log test completion
    Add-EnterpriseLog -Level "INFO" -Message "Production testing completed" -Category "Testing" -AdditionalData @{
        TestType = $TestType
        OverallSuccess = $testResults.OverallSuccess
        SuccessRate = $testResults.SuccessRate
        TotalTests = $testResults.TotalTests
        PassedTests = $testResults.PassedTests
        FailedTests = $testResults.FailedTests
    }

    Add-AuditTrailEntry -EventType "SystemEvent" -Action "Production testing completed" -Result $(if ($testResults.OverallSuccess) { "Success" } else { "Failure" }) -Details "Success Rate: $($testResults.SuccessRate)%"

    # Final verdict
    Write-Host ""
    if ($testResults.OverallSuccess) {
        Write-StatusMessage -Message "Production testing PASSED!" -Type Success
        Write-Host "  All tests completed successfully with $($testResults.SuccessRate)% success rate" -ForegroundColor Green
    } else {
        Write-StatusMessage -Message "Production testing FAILED!" -Type Error
        Write-Host "  Tests completed with $($testResults.SuccessRate)% success rate" -ForegroundColor Red
        Write-Host "  Review failed tests above for details" -ForegroundColor Red
    }

    Write-Host ""

} catch {
    # Log test failure
    Add-EnterpriseLog -Level "ERROR" -Message "Production testing failed" -Category "Testing" -Exception $_
    Add-AuditTrailEntry -EventType "Error" -Action "Production testing" -Result "Failure" -Details "Error: $($_.Exception.Message)"

    Write-Host ""
    Write-StatusMessage -Message "Production testing failed!" -Type Error
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    throw
}