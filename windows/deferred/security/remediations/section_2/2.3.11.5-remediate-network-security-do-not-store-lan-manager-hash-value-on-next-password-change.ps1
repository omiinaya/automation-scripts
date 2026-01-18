<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.5: Network security: Do not store LAN Manager hash value on next password change

.DESCRIPTION
    This script remediates the configuration of 'Network security: Do not store LAN Manager hash value on next password change' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.5-remediate-network-security-do-not-store-lan-manager-hash-value-on-next-password-change.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.5
    Title: Ensure 'Network security: Do not store LAN Manager hash value on next password change' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: NoLMHash
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.5"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "NoLMHash"
$RegistryValueData = 1
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult