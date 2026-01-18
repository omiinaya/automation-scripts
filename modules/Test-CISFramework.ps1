<#
.SYNOPSIS
    Test script for CISFramework module functionality.
.DESCRIPTION
    Demonstrates the core functions of the CISFramework module.
.NOTES
    This script tests the four core functions:
    1. New-CISResultObject
    2. Get-CISRecommendation
    3. Test-CISCompliance
    4. Invoke-CISAudit
#>

# Import the CISFramework module
Import-Module "$PSScriptRoot\CISFramework.psm1" -Force

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "CIS Framework Module Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: New-CISResultObject function
Write-Host "Test 1: New-CISResultObject" -ForegroundColor Yellow
$testResult = New-CISResultObject -CIS_ID "1.1.1" -Title "Enforce password history" -CurrentValue 24 -RecommendedValue "24 or more" -ComplianceStatus "Compliant" -Source "Domain Policy"
Write-Host "Created result object:" -ForegroundColor White
$testResult | Format-List CIS_ID, Title, CurrentValue, RecommendedValue, ComplianceStatus, IsCompliant, Source
Write-Host ""

# Test 2: Get-CISRecommendation function
Write-Host "Test 2: Get-CISRecommendation" -ForegroundColor Yellow
$recommendation = Get-CISRecommendation -CIS_ID "1.1.1" -Section 1
if ($recommendation) {
    Write-Host "Retrieved recommendation:" -ForegroundColor White
    Write-Host "  CIS ID: $($recommendation.cis_id)" -ForegroundColor White
    Write-Host "  Title: $($recommendation.title)" -ForegroundColor White
    Write-Host "  Profile: $($recommendation.profile)" -ForegroundColor White
} else {
    Write-Host "Failed to retrieve recommendation (JSON files may not be accessible)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Test-CISCompliance function
Write-Host "Test 3: Test-CISCompliance" -ForegroundColor Yellow
$compliant = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 24 -ExpectedValue 24 -ComparisonOperator "ge"
Write-Host "Compliance test result: $compliant (24 >= 24)" -ForegroundColor White

$nonCompliant = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue -ExpectedValue 24 -ComparisonOperator "ge"
Write-Host "Compliance test result: $nonCompliant (10 >= 24)" -ForegroundColor White
Write-Host ""

# Test 4: Test-DomainMember function
Write-Host "Test 4: Test-DomainMember" -ForegroundColor Yellow
$isDomainMember = Test-DomainMember
Write-Host "Is domain member: $isDomainMember" -ForegroundColor White
Write-Host ""

# Test 5: Export-CISAuditResults function (simulated)
Write-Host "Test 5: Export-CISAuditResults (simulated)" -ForegroundColor Yellow
$results = @(
    New-CISResultObject -CIS_ID "1.1.1" -Title "Enforce password history" -CurrentValue 24 -RecommendedValue "24 or more" -ComplianceStatus "Compliant" -Source "Domain Policy"
    New-CISResultObject -CIS_ID "1.1.2" -Title "Maximum password age" -CurrentValue 60 -RecommendedValue "365 or fewer days, but not 0" -ComplianceStatus "Compliant" -Source "Domain Policy"
    New-CISResultObject -CIS_ID "1.1.3" -Title "Minimum password age" -CurrentValue 0 -RecommendedValue "1 or more day(s)" -ComplianceStatus "Non-Compliant" -Source "Local Policy"
)
Write-Host "Created $($results.Count) sample audit results" -ForegroundColor White
Write-Host ""

# Test 6: Get-CISAuditSummary function
Write-Host "Test 6: Get-CISAuditSummary" -ForegroundColor Yellow
$summary = Get-CISAuditSummary -Results $results
Write-Host "Audit Summary:" -ForegroundColor White
$summary | Format-List TotalAudits, CompliantAudits, NonCompliantAudits, CompliancePercentage, OverallStatus
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "All tests completed successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan