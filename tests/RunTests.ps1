<#
.SYNOPSIS
    Pester test runner script for CIS automation scripts
.DESCRIPTION
    Provides a comprehensive test runner for executing Pester tests
    with various configurations and reporting options.
.NOTES
    File Name      : RunTests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

param(
    [Parameter()]
    [ValidateSet("Unit", "Integration", "All")]
    [string]$TestType = "All",
    
    [Parameter()]
    [string]$OutputPath,
    
    [Parameter()]
    [switch]$CodeCoverage,
    
    [Parameter()]
    [switch]$Verbose,
    
    [Parameter()]
    [switch]$Quiet,
    
    [Parameter()]
    [string]$ConfigurationFile = "PesterConfig.psd1"
)

# Import test helpers
Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force

# Set up test paths
$testRoot = $PSScriptRoot
$unitTestsPath = "$testRoot\unit"
$integrationTestsPath = "$testRoot\integration"
$resultsPath = "$testRoot\results"
$logsPath = "$testRoot\logs"

# Create results and logs directories if they don't exist
if (-not (Test-Path $resultsPath)) {
    New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
}

if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

# Determine which tests to run
$testPaths = @()

switch ($TestType) {
    "Unit" {
        $testPaths += $unitTestsPath
        Write-Host "Running unit tests..." -ForegroundColor Cyan
    }
    "Integration" {
        $testPaths += $integrationTestsPath
        Write-Host "Running integration tests..." -ForegroundColor Cyan
    }
    "All" {
        $testPaths += $unitTestsPath
        $testPaths += $integrationTestsPath
        Write-Host "Running all tests..." -ForegroundColor Cyan
    }
}

# Build Pester configuration
$pesterConfig = @{
    Run = @{
        Path = $testPaths
        PassThru = $true
    }
    Output = @{}
    TestResult = @{
        Enabled = $true
        OutputPath = "$resultsPath\test-results.xml"
        OutputFormat = "NUnitXml"
    }
}

# Add code coverage if requested
if ($CodeCoverage) {
    $pesterConfig.CodeCoverage = @{
        Enabled = $true
        Include = @(
            "..\modules\*.psm1",
            "..\modules\*.ps1"
        )
        OutputPath = "$resultsPath\coverage.xml"
        OutputFormat = "CoverageGutters"
        CoveragePercentTarget = 70
    }
}

# Configure output verbosity
if ($Verbose) {
    $pesterConfig.Output.Verbosity = "Detailed"
} elseif ($Quiet) {
    $pesterConfig.Output.Verbosity = "Minimal"
} else {
    $pesterConfig.Output.Verbosity = "Normal"
}

# Use configuration file if specified
if (Test-Path "$testRoot\$ConfigurationFile") {
    $pesterConfig = Import-PowerShellDataFile -Path "$testRoot\$ConfigurationFile"
    Write-Host "Using configuration from: $ConfigurationFile" -ForegroundColor Green
}

# Display test configuration
Write-Host ""
Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Test Type: $TestType" -ForegroundColor White
Write-Host "  Test Paths: $($testPaths -join ', ')" -ForegroundColor White
Write-Host "  Code Coverage: $CodeCoverage" -ForegroundColor White
Write-Host "  Verbosity: $($pesterConfig.Output.Verbosity)" -ForegroundColor White
Write-Host ""

# Run tests
try {
    Write-Host "Starting tests..." -ForegroundColor Green
    
    $testResults = Invoke-Pester -Configuration $pesterConfig
    
    # Display summary
    Write-Host ""
    Write-Host "Test Summary:" -ForegroundColor Yellow
    Write-Host "  Total: $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor Red
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Pending: $($testResults.PendingCount)" -ForegroundColor Gray
    Write-Host "  Time: $($testResults.Duration.ToString())" -ForegroundColor White
    
    if ($testResults.CodeCoverage) {
        Write-Host "  Code Coverage: $([math]::Round($testResults.CodeCoverage.NumberOfCommandsAnalyzed / $testResults.CodeCoverage.NumberOfCommands * 100, 2))%" -ForegroundColor Cyan
    }
    
    Write-Host ""
    
    # Save detailed results
    if ($OutputPath) {
        $testResults | Export-Clixml -Path $OutputPath
        Write-Host "Detailed results saved to: $OutputPath" -ForegroundColor Green
    }
    
    # Save test results to XML
    $testResults | Export-Clixml -Path "$resultsPath\detailed-results.xml"
    
    # Generate HTML report (if Pester supports it)
    if (Get-Command "ConvertTo-Html" -ErrorAction SilentlyContinue) {
        $htmlReport = $testResults | ConvertTo-Html -Title "CIS Automation Scripts Test Results"
        $htmlReport | Out-File -FilePath "$resultsPath\test-results.html" -Encoding UTF8
        Write-Host "HTML report saved to: $resultsPath\test-results.html" -ForegroundColor Green
    }
    
    # Set exit code based on test results
    if ($testResults.FailedCount -gt 0) {
        Write-Host "Tests completed with failures. Exit code: 1" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "All tests passed successfully!" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error "Test execution failed: $_"
    exit 1
}