<#
.SYNOPSIS
    Pester tests for CISRemediation module functions
.DESCRIPTION
    Unit tests for CISRemediation module functions including result object creation,
    security policy templates, domain instructions, and remediation functionality.
.NOTES
    File Name      : CISRemediation.Tests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

# Import the module to test
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

Describe "CISRemediation Module Tests" {
    Context "New-CISRemediationResult Function" {
        It "Should create a valid CIS remediation result object with required parameters" {
            $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test Title" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated" -IsCompliant $true -RequiresManualAction $false
            
            $result.CIS_ID | Should -Be "1.1.1"
            $result.Title | Should -Be "Test Title"
            $result.PreviousValue | Should -Be "0"
            $result.NewValue | Should -Be "24"
            $result.Status | Should -Be "Remediated"
            $result.Message | Should -Be "Successfully updated"
            $result.IsCompliant | Should -Be $true
            $result.RequiresManualAction | Should -Be $false
            $result.RemediationTimestamp | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Not -BeNullOrEmpty
            $result.UserName | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle Failed status correctly" {
            $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test Title" -PreviousValue "0" -NewValue "0" -Status "Failed" -Message "Failed to update" -IsCompliant $false -RequiresManualAction $true
            
            $result.IsCompliant | Should -Be $false
            $result.RequiresManualAction | Should -Be $true
        }
        
        It "Should handle ManualActionRequired status correctly" {
            $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test Title" -PreviousValue "0" -NewValue "0" -Status "ManualActionRequired" -Message "Manual action required" -IsCompliant $false -RequiresManualAction $true
            
            $result.Status | Should -Be "ManualActionRequired"
            $result.RequiresManualAction | Should -Be $true
        }
        
        It "Should handle optional parameters correctly" {
            $result = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test Title" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated" -IsCompliant $true -RequiresManualAction $false -Source "Registry" -ErrorMessage ""
            
            $result.Source | Should -Be "Registry"
            $result.ErrorMessage | Should -Be ""
        }
    }
    
    Context "Get-DomainRemediationInstructions Function" {
        It "Should return domain remediation instructions object" {
            $instructions = Get-DomainRemediationInstructions -CIS_ID "1.1.1" -SettingName "Enforce password history" -RecommendedValue "24 or more"
            
            $instructions.CIS_ID | Should -Be "1.1.1"
            $instructions.SettingName | Should -Be "Enforce password history"
            $instructions.RecommendedValue | Should -Be "24 or more"
            $instructions.Instructions | Should -Not -BeNullOrEmpty
            $instructions.ManualActionRequired | Should -Be $true
            $instructions.Instructions | Should -Match "DOMAIN REMEDIATION INSTRUCTIONS"
            $instructions.Instructions | Should -Match "Group Policy Management Console"
        }
    }
    
    Context "Get-CISRemediationSummary Function" {
        It "Should generate a summary from remediation results" {
            $results = @(
                New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test 1" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Success" -IsCompliant $true -RequiresManualAction $false,
                New-CISRemediationResult -CIS_ID "1.1.2" -Title "Test 2" -PreviousValue "0" -NewValue "0" -Status "Failed" -Message "Failure" -IsCompliant $false -RequiresManualAction $true,
                New-CISRemediationResult -CIS_ID "1.1.3" -Title "Test 3" -PreviousValue "0" -NewValue "0" -Status "ManualActionRequired" -Message "Manual" -IsCompliant $false -RequiresManualAction $true
            )
            
            $summary = Get-CISRemediationSummary -Results $results
            
            $summary.TotalRemediations | Should -Be 3
            $summary.SuccessfulRemediations | Should -Be 1
            $summary.ManualActionRequired | Should -Be 2
            $summary.FailedRemediations | Should -Be 1
            $summary.SuccessPercentage | Should -Be 33.33
            $summary.OverallStatus | Should -Be "Poor"
            $summary.RemediationTimestamp | Should -Not -BeNullOrEmpty
            $summary.ComputerName | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle empty results gracefully" {
            $summary = Get-CISRemediationSummary -Results @()
            
            $summary.TotalRemediations | Should -Be 0
            $summary.SuccessPercentage | Should -Be 0
            $summary.OverallStatus | Should -Be "Poor"
        }
        
        It "Should calculate correct success percentages" {
            $results = @(
                New-CISRemediationResult -CIS_ID "1.1.1" -Title "Test 1" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Success" -IsCompliant $true -RequiresManualAction $false,
                New-CISRemediationResult -CIS_ID "1.1.2" -Title "Test 2" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Success" -IsCompliant $true -RequiresManualAction $false,
                New-CISRemediationResult -CIS_ID "1.1.3" -Title "Test 3" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Success" -IsCompliant $true -RequiresManualAction $false
            )
            
            $summary = Get-CISRemediationSummary -Results $results
            
            $summary.SuccessPercentage | Should -Be 100
            $summary.OverallStatus | Should -Be "Excellent"
        }
    }
    
    Context "Mock Functions for Complex Testing" {
        BeforeAll {
            # Mock the Test-DomainMember function to control domain environment testing
            Mock Test-DomainMember { return $false }
            
            # Mock Get-CISRecommendation for consistent testing
            Mock Get-CISRecommendation { 
                return @{
                    cis_id = "1.1.1"
                    title = "Enforce password history"
                    profile = "L1"
                }
            }
        }
        
        It "Should handle registry remediation scenarios" {
            Mock Set-RegistryValue { return $true }
            
            $result = Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Test" -RegistryValueName "TestValue" -RegistryValueData 1 -AutoConfirm
            
            $result.CIS_ID | Should -Be "1.1.1"
            $result.Status | Should -Be "Remediated"
        }
        
        It "Should handle missing parameters gracefully" {
            $result = Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "Registry" -AutoConfirm
            
            $result.Status | Should -Be "Error"
            $result.Message | Should -Match "Registry path, value name, and value data required"
        }
        
        It "Should handle custom remediation scenarios" {
            $scriptBlock = {
                return @{
                    PreviousValue = "0"
                    NewValue = "24"
                }
            }
            
            $result = Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "Custom" -CustomScriptBlock $scriptBlock -AutoConfirm
            
            $result.Status | Should -Be "Remediated"
            $result.PreviousValue | Should -Be "0"
            $result.NewValue | Should -Be "24"
        }
    }
}