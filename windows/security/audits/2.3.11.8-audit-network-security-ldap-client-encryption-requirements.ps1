<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.8: Network security: LDAP client encryption requirements

.DESCRIPTION
    This script audits the configuration of 'Network security: LDAP client encryption requirements' 
    to ensure it is set to 'Negotiate sealing' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.8-audit-network-security-ldap-client-encryption-requirements.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.8
    Title: Ensure 'Network security: LDAP client encryption requirements' is set to 'Negotiate sealing' or higher
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LDAP
    Registry Value: LDAPClientConfidentiality
    Recommended Value: 1 or 2
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.8"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LDAP"
$RegistryValueName = "LDAPClientConfidentiality"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult