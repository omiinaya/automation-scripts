<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.12: Network access: Sharing and security model for local accounts

.DESCRIPTION
    This script audits the configuration of 'Network access: Sharing and security model for local accounts' 
    to ensure it is set to 'Classic - local users authenticate as themselves' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.12-audit-network-access-sharing-and-security-model-for-local-accounts.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.12
    Title: Ensure 'Network access: Sharing and security model for local accounts' is set to 'Classic - local users authenticate as themselves'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: ForceGuest
    Recommended Value: 0 (Classic - local users authenticate as themselves)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.12"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "ForceGuest"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult