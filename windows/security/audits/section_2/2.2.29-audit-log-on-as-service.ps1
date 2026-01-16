<#
.SYNOPSIS
    CIS Audit Script for 2.2.29 - Ensure 'Log on as a service' is configured
.DESCRIPTION
    This script audits the user right assignment for logging on as a service.
    The recommended state is: No One or (when the Hyper-V feature is installed) NT VIRTUAL MACHINE\Virtual Machines or (when using Windows Defender Application Guard) WDAGUtilityAccount.
.NOTES
    CIS ID: 2.2.29
    Profile: L2
    File Name: 2.2.29-audit-log-on-as-service.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform the audit
$auditResult = Invoke-CISAudit -CIS_ID "2.2.29" -AuditType "GroupPolicy" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -RegistryValueName "SeServiceLogonRight" -VerboseOutput

# Output the result
if ($auditResult.ComplianceStatus -eq "Compliant") {
    Write-Host "CIS 2.2.29 Audit Result: COMPLIANT" -ForegroundColor Green
    Write-Host "The 'Log on as a service' user right is correctly configured" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.29 Audit Result: NON-COMPLIANT" -ForegroundColor Red
    Write-Host "Current setting: $($auditResult.CurrentValue)" -ForegroundColor Yellow
    Write-Host "Recommended: No One or NT VIRTUAL MACHINE\Virtual Machines or WDAGUtilityAccount" -ForegroundColor Yellow
}

# Return the compliance status for automated testing
return $auditResult.ComplianceStatus