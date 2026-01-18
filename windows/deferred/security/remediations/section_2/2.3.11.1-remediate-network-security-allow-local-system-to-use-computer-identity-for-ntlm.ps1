<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.1: Network security: Allow Local System to use computer identity for NTLM

.DESCRIPTION
    This script remediates the configuration of 'Network security: Allow Local System to use computer identity for NTLM' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.1-remediate-network-security-allow-local-system-to-use-computer-identity-for-ntlm.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.1
    Title: Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: UseMachineId
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.1"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "UseMachineId"
$RegistryValueData = 1
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult