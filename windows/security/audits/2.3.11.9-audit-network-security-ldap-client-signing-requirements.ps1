<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.9: Network security: LDAP client signing requirements

.DESCRIPTION
    This script audits the configuration of 'Network security: LDAP client signing requirements' 
    to ensure it is set to 'Negotiate signing' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.9-audit-network-security-ldap-client-signing-requirements.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.9
    Title: Ensure 'Network security: LDAP client signing requirements' is set to 'Negotiate signing' or higher
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LDAP
    Registry Value: LDAPClientIntegrity
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.9"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LDAP"
$RegistryValueName = "LDAPClientIntegrity"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult