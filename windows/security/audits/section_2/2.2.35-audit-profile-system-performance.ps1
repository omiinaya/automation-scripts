<#
.SYNOPSIS
    CIS Audit Script for 2.2.35 - Ensure 'Profile system performance' is set to 'Administrators, NT SERVICE\WdiServiceHost'
.DESCRIPTION
    This script audits the user right assignment for profiling system performance.
    The recommended state is: Administrators, NT SERVICE\WdiServiceHost.
.NOTES
    CIS ID: 2.2.35
    Profile: L1
    File Name: 2.2.35-audit-profile-system-performance.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.35" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeSystemProfilePrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.35 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Profile system performance' user right is correctly set to 'Administrators, NT SERVICE\WdiServiceHost'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.35 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: Administrators, NT SERVICE\WdiServiceHost" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus