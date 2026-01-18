<#
.SYNOPSIS
    Pester tests for CISFramework module functions
.DESCRIPTION
    Unit tests for CISFramework module functions including result object creation,
    recommendation retrieval, compliance testing, and audit functionality.
.NOTES
    File Name      : CISFramework.Tests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

# Import the module to test
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

Describe "CISFramework Module Tests" {
    Context "New-CISResultObject Function" {
        It "Should create a valid CIS result object with required parameters" {
            $result = New-CISResultObject -CIS_ID "1.1.1" -Title "Test Title" -CurrentValue "24" -RecommendedValue "24 or more" -ComplianceStatus "Compliant"
            
            $result.CIS_ID | Should -Be "1.1.1"
            $result.Title | Should -Be "Test Title"
            $result.CurrentValue | Should -Be "24"
            $result.RecommendedValue | Should -Be "24 or more"
            $result.ComplianceStatus | Should -Be "Compliant"
            $result.IsCompliant | Should -Be $true
            $result.AuditTimestamp | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Not -BeNullOrEmpty
            $result.UserName | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle Non-Compliant status correctly" {
            $result = New-CISResultObject -CIS_ID "1.1.1" -Title "Test Title" -CurrentValue "0" -RecommendedValue "24 or more" -ComplianceStatus "Non-Compliant"
            
            $result.IsCompliant | Should -Be $false
        }
        
        It "Should handle optional parameters correctly" {
            $result = New-CISResultObject -CIS_ID "1.1.1" -Title "Test Title" -CurrentValue "24" -RecommendedValue "24 or more" -ComplianceStatus "Compliant" -Source "Registry" -Details "Test details" -ErrorMessage "" -Profile "L1"
            
            $result.Source | Should -Be "Registry"
            $result.Details | Should -Be "Test details"
            $result.ErrorMessage | Should -Be ""
            $result.Profile | Should -Be "L1"
        }
    }
    
    Context "Get-CISRecommendation Function" {
        BeforeAll {
            # Create a mock JSON file for testing
            $testJsonPath = "$PSScriptRoot\..\..\docs\json\test_section.json"
            $testData = @(
                @{
                    cis_id = "1.1.1"
                    title = "Enforce password history"
                    profile = "L1"
                },
                @{
                    cis_id = "1.1.2"
                    title = "Maximum password age"
                    profile = "L1"
                }
            )
            $testData | ConvertTo-Json | Set-Content -Path $testJsonPath
        }
        
        AfterAll {
            # Clean up test file
            Remove-Item $testJsonPath -ErrorAction SilentlyContinue
        }
        
        It "Should retrieve a recommendation from JSON file" {
            $recommendation = Get-CISRecommendation -CIS_ID "1.1.1" -JsonPath $testJsonPath
            
            $recommendation.cis_id | Should -Be "1.1.1"
            $recommendation.title | Should -Be "Enforce password history"
            $recommendation.profile | Should -Be "L1"
        }
        
        It "Should return null for non-existent recommendation" {
            $recommendation = Get-CISRecommendation -CIS_ID "9.9.9" -JsonPath $testJsonPath
            
            $recommendation | Should -BeNullOrEmpty
        }
        
        It "Should handle invalid JSON path gracefully" {
            $recommendation = Get-CISRecommendation -CIS_ID "1.1.1" -JsonPath "nonexistent.json"
            
            $recommendation | Should -BeNullOrEmpty
        }
    }
    
    Context "Test-CISCompliance Function" {
        It "Should return true for equal values" {
            $result = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 24 -ExpectedValue 24 -ComparisonOperator "eq"
            
            $result | Should -Be $true
        }
        
        It "Should return false for unequal values" {
            $result = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 0 -ExpectedValue 24 -ComparisonOperator "eq"
            
            $result | Should -Be $false
        }
        
        It "Should handle greater than or equal comparison" {
            $result = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 24 -ExpectedValue 24 -ComparisonOperator "ge"
            
            $result | Should -Be $true
        }
        
        It "Should handle less than or equal comparison" {
            $result = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue 0 -ExpectedValue 24 -ComparisonOperator "le"
            
            $result | Should -Be $true
        }
        
        It "Should handle string comparisons" {
            $result = Test-CISCompliance -CIS_ID "1.1.1" -CurrentValue "Enabled" -ExpectedValue "Enabled" -ComparisonOperator "eq"
            
            $result | Should -Be $true
        }
    }
    
    Context "Test-DomainMember Function" {
        It "Should return a boolean value" {
            $result = Test-DomainMember
            
            $result | Should -BeOfType [bool]
        }
    }
    
    Context "Get-CISAuditSummary Function" {
        It "Should generate a summary from audit results" {
            $results = @(
                New-CISResultObject -CIS_ID "1.1.1" -Title "Test 1" -CurrentValue "24" -RecommendedValue "24 or more" -ComplianceStatus "Compliant",
                New-CISResultObject -CIS_ID "1.1.2" -Title "Test 2" -CurrentValue "0" -RecommendedValue "24 or more" -ComplianceStatus "Non-Compliant"
            )
            
            $summary = Get-CISAuditSummary -Results $results
            
            $summary.TotalAudits | Should -Be 2
            $summary.CompliantAudits | Should -Be 1
            $summary.NonCompliantAudits | Should -Be 1
            $summary.CompliancePercentage | Should -Be 50
            $summary.OverallStatus | Should -Be "Fair"
            $summary.AuditTimestamp | Should -Not -BeNullOrEmpty
            $summary.ComputerName | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle empty results gracefully" {
            $summary = Get-CISAuditSummary -Results @()
            
            $summary.TotalAudits | Should -Be 0
            $summary.CompliancePercentage | Should -Be 0
            $summary.OverallStatus | Should -Be "Poor"
        }
    }
}