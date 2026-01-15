<#
.SYNOPSIS
    Integration tests for CIS audit scripts
.DESCRIPTION
    Integration tests that verify audit script behavior, file structure,
    and basic functionality without executing actual system changes.
.NOTES
    File Name      : AuditScripts.Tests.ps1
    Author         : System Administrator
    Prerequisite   : Pester module
#>

Describe "CIS Audit Scripts Integration Tests" {
    Context "Audit Script File Structure" {
        It "Should have audit scripts in the correct directory" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            Test-Path $auditScriptsPath | Should -Be $true
        }
        
        It "Should have audit scripts with proper naming convention" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $auditScripts = Get-ChildItem -Path $auditScriptsPath -Filter "*-audit-*.ps1"
            
            $auditScripts.Count | Should -BeGreaterThan 0
            
            foreach ($script in $auditScripts) {
                $script.Name | Should -Match "^\d+\.\d+\.\d+-audit-" 
                $script.Name | Should -Match "\.ps1$"
            }
        }
        
        It "Should have proper script headers and documentation" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $auditScripts = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1"
            
            foreach ($script in $auditScripts) {
                $content = Get-Content -Path $script.FullName -Raw
                $content | Should -Match "\.SYNOPSIS"
                $content | Should -Match "\.DESCRIPTION"
                $content | Should -Match "\.NOTES"
                $content | Should -Match "File Name"
            }
        }
    }
    
    Context "Audit Script Content Validation" {
        It "Should import required modules correctly" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Import-Module"
                $content | Should -Match "CISFramework"
            }
        }
        
        It "Should use standardized CIS functions" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Invoke-CISAudit"
                $content | Should -Match "New-CISResultObject"
                $content | Should -Match "Get-CISRecommendation"
            }
        }
        
        It "Should have proper error handling" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "try\s*{"
                $content | Should -Match "catch\s*{"
                $content | Should -Match "ErrorAction"
            }
        }
    }
    
    Context "Audit Script Parameter Validation" {
        It "Should have proper parameter blocks" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "param\s*\("
                $content | Should -Match "\[Parameter\]",
            }
        }
        
        It "Should support common parameters like Verbose" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "\[switch\]\$Verbose"
            }
        }
    }
    
    Context "Audit Script Output Validation" {
        It "Should produce standardized output objects" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "Write-Output"
                $content | Should -Match "Write-Host"
                $content | Should -Match "Write-StatusMessage"
            }
        }
        
        It "Should support both console output and object return" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "*.ps1" | Select-Object -First 1
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                # Should have both output mechanisms
                ($content -match "Write-Host" -or $content -match "Write-StatusMessage") | Should -Be $true
                ($content -match "return" -or $content -match "Write-Output") | Should -Be $true
            }
        }
    }
    
    Context "Sample Audit Script Test" {
        It "Should be able to parse a sample audit script without errors" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "1.1.1-audit-password-history.ps1"
            
            if ($sampleScript) {
                # Test that the script can be parsed (syntax check)
                { Invoke-Expression (Get-Content -Path $sampleScript.FullName -Raw) } | Should -Not -Throw
            }
        }
        
        It "Should contain CIS benchmark references" {
            $auditScriptsPath = "$PSScriptRoot\..\..\windows\security\audits"
            $sampleScript = Get-ChildItem -Path $auditScriptsPath -Filter "1.1.1-audit-password-history.ps1"
            
            if ($sampleScript) {
                $content = Get-Content -Path $sampleScript.FullName -Raw
                $content | Should -Match "1\.1\.1"
                $content | Should -Match "password history"
            }
        }
    }
}