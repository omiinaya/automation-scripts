<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.5: Network security: Do not store LAN Manager hash value on next password change

.DESCRIPTION
    This script audits the configuration of 'Network security: Do not store LAN Manager hash value on next password change' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.5-audit-network-security-do-not-store-lan-manager-hash-value-on-next-password-change.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.5
    Title: Ensure 'Network security: Do not store LAN Manager hash value on next password change' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: NoLMHash
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.5"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "NoLMHash"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult