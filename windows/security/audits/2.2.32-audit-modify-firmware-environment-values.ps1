<#
.SYNOPSIS
    CIS Audit Script for 2.2.32 - Ensure 'Modify firmware environment values' is set to 'Administrators'
.DESCRIPTION
    This script audits the user right assignment for modifying firmware environment values.
    The recommended state is: Administrators.
.NOTES
    CIS ID: 2.2.32
    Profile: L1
    File Name: 2.2.32-audit-modify-firmware-environment-values.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.32" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeSystemEnvironmentPrivilege" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.32 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Modify firmware environment values' user right is correctly set to 'Administrators'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.32 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: Administrators" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus