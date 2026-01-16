<#
.SYNOPSIS
    CIS Audit Script for 2.2.27 - Ensure 'Lock pages in memory' is set to 'No One'
.DESCRIPTION
    This script audits the user right assignment for locking pages in memory.
    The recommended state is: No One.
.NOTES
    CIS ID: 2.2.27
    Profile: L1
    File Name: 2.2.27-audit-lock-pages-in-memory.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.27" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeLockMemoryPrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.27 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Lock pages in memory' user right is correctly set to 'No One'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.27 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: No One" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus