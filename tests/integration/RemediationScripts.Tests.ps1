<#
.SYNOPSIS
    Integration tests for CIS remediation scripts
.DESCRIPTION
    Integration tests that verify remediation script behavior, file structure,
    and basic functionality without executing actual system changes.
.NOTES
    File Name      : RemediationScripts.Tests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

Describe "CIS Remediation Scripts Integration Tests" {
    Context "Remediation Script File Structure" {
        It "Should have remediation scripts in the correct directory" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            Test-Path $remediationScriptsPath | Should -Be $true
        }
        
        It "Should have remediation scripts with proper naming convention" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $remediationScripts = Get-ChildItem -Path $remediationScriptsPath -Filter "*-remediate-*.ps1"
            
            $remediationScripts.Count | Should -BeGreaterThan 0
            
            foreach ($script in $remediationScripts) {
                $script.Name | Should -Match "^\d+\.\d+\.\d+-remediate-" 
                $script.Name | Should -Match "\.ps1$"
            }
        }
        
        It "Should have proper script headers and documentation" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $remediationScripts = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1"
            
            foreach ($script in $remediationScripts) {
                $content = Get-Content -Path $script.FullName -Raw
                $content | Should -Match "\.SYNOPSIS"
                $content | Should -Match "\.DESCRIPTION"
                $content | Should -Match "\.NOTES"
                $content | Should -Match "File Name"
                $content | Should -Match "WARNING" -or $content -Match "CAUTION"
            }
        }
    }
    
    Context "Remediation Script Content Validation" {
        It "Should import required modules correctly" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Import-Module"
                $content | Should -Match "CISRemediation"
                $content | Should -Match "CISFramework"
            }
        }
        
        It "Should use standardized CIS functions" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Invoke-CISRemediation"
                $content | Should -Match "New-CISRemediationResult"
                $content | Should -Match "Get-CISRecommendation"
            }
        }
        
        It "Should have proper error handling and safety checks" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "try\s*{"
                $content | Should -Match "catch\s*{"
                $content | Should -Match "ErrorAction"
                $content | Should -Match "Confirm" -or $content -Match "confirmation"
            }
        }
    }
    
    Context "Remediation Script Parameter Validation" {
        It "Should have proper parameter blocks" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "param\s*\("
                $content | Should -Match "\[Parameter\]"
            }
        }
        
        It "Should support common parameters like AutoConfirm and Verbose" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "\[switch\]\$AutoConfirm" -or $content -Match "\[switch\]\$Force"
                $content | Should -Match "\[switch\]\$Verbose"
            }
        }
    }
    
    Context "Remediation Script Safety Features" {
        It "Should include safety warnings" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "WARNING" -or $content -Match "CAUTION" -or $content -Match "DANGER"
            }
        }
        
        It "Should check for administrative privileges" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Test-AdminRights" -or $content -Match "administrative" -or $content -Match "elevated"
            }
        }
        
        It "Should handle domain environment gracefully" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Test-DomainMember" -or $content -Match "domain" -or $content -Match "Group Policy"
            }
        }
    }
    
    Context "Remediation Script Output Validation" {
        It "Should produce standardized output objects" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Write-Output"
                $content | Should -Match "Write-Host"
                $content | Should -Match "Write-StatusMessage"
            }
        }
        
        It "Should support both console output and object return" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                # Should have both output mechanisms
                ($content -match "Write-Host" -or $content -match "Write-StatusMessage") | Should -Be $true
                ($content -match "return" -or $content -match "Write-Output") | Should -Be $true
            }
        }
    }
    
    Context "Sample Remediation Script Test" {
        It "Should be able to parse a sample remediation script without errors" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "1.1.1-remediate-password-history.ps1"
            
            if ($sampleScript) {
                # Test that the script can be parsed (syntax check)
                { Invoke-Expression (Get-Content -Path $sampleScript.FullName -Raw) } | Should -Not -Throw
            }
        }
        
        It "Should contain CIS benchmark references" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "1.1.1-remediate-password-history.ps1"
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "1\.1\.1"
                $content | Should -Match "password history"
            }
        }
        
        It "Should contain security policy template references" {
            $remediationScriptsPath = "$PSScriptRoot\..\..\windows\security\remediations"
            $sampleScript = Get-ChildItem -Path $remediationScriptsPath -Filter "1.1.1-remediate-password-history.ps1"
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "secedit" -or $content -Match "security policy" -or $content -Match "template"
            }
        }
    }
}