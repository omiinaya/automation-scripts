<#
.SYNOPSIS
    CIS Audit Script for 2.2.31 - Ensure 'Modify an object label' is set to 'No One'
.DESCRIPTION
    This script audits the user right assignment for modifying object labels.
    The recommended state is: No One.
.NOTES
    CIS ID: 2.2.31
    Profile: L1
    File Name: 2.2.31-audit-modify-object-label.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.31" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeRelabelPrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.31 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Modify an object label' user right is correctly set to 'No One'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.31 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: No One" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus