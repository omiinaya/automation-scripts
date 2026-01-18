<#
.SYNOPSIS
    CIS Audit Script for 2.2.23 - Ensure 'Generate security audits' is set to 'LOCAL SERVICE, NETWORK SERVICE'
.DESCRIPTION
    This script audits the user right assignment for generating security audits.
    The recommended state is: LOCAL SERVICE, NETWORK SERVICE.
.NOTES
    CIS ID: 2.2.23
    Profile: L1
    File Name: 2.2.23-audit-generate-security-audits.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.23" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeAuditPrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.23 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Generate security audits' user right is correctly set to 'LOCAL SERVICE, NETWORK SERVICE'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.23 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: LOCAL SERVICE, NETWORK SERVICE" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus