<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.12: Network access: Sharing and security model for local accounts

.DESCRIPTION
    This script remediates the configuration of 'Network access: Sharing and security model for local accounts' 
    to set it to 'Classic - local users authenticate as themselves' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.12-remediate-network-access-sharing-and-security-model-for-local-accounts.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.12
    Title: Ensure 'Network access: Sharing and security model for local accounts' is set to 'Classic - local users authenticate as themselves'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: ForceGuest
    Recommended Value: 0 (Classic - local users authenticate as themselves)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.12"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "ForceGuest"
$RegistryValueData = 0
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult