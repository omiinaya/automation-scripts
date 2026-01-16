<#
.SYNOPSIS
    CIS Audit Script for 2.2.24 - Ensure 'Impersonate a client after authentication' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE'
.DESCRIPTION
    This script audits the user right assignment for impersonating a client after authentication.
    The recommended state is: Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE.
.NOTES
    CIS ID: 2.2.24
    Profile: L1
    File Name: 2.2.24-audit-impersonate-client-after-authentication.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.24" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeImpersonatePrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.24 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Impersonate a client after authentication' user right is correctly set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.24 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus