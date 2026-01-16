<#
.SYNOPSIS
    Audit script for CIS ID 2.3.17.6: User Account Control: Run all administrators in Admin Approval Mode

.DESCRIPTION
    This script audits the configuration of 'User Account Control: Run all administrators in Admin Approval Mode' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.6-audit-user-account-control-run-all-administrators-admin-approval-mode.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.17.6
    Title: Ensure 'User Account Control: Run all administrators in Admin Approval Mode' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: EnableLUA
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.17.6"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "EnableLUA"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult