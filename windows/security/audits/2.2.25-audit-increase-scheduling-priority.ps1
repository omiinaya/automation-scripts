<#
.SYNOPSIS
    CIS Audit Script for 2.2.25 - Ensure 'Increase scheduling priority' is set to 'Administrators, Window Manager\Window Manager Group'
.DESCRIPTION
    This script audits the user right assignment for increasing scheduling priority.
    The recommended state is: Administrators, Window Manager\Window Manager Group.
.NOTES
    CIS ID: 2.2.25
    Profile: L1
    File Name: 2.2.25-audit-increase-scheduling-priority.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.25" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeIncreaseBasePriorityPrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.25 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Increase scheduling priority' user right is correctly set to 'Administrators, Window Manager\Window Manager Group'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.25 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: Administrators, Window Manager\Window Manager Group" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus