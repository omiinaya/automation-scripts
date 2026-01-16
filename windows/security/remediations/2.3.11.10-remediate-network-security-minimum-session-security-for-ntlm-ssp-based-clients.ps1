<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.10: Network security: Minimum session security for NTLM SSP based (including secure RPC) clients

.DESCRIPTION
    This script remediates the configuration of 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' 
    to set it to 'Require NTLMv2 session security, Require 128-bit encryption' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.10-remediate-network-security-minimum-session-security-for-ntlm-ssp-based-clients.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.10
    Title: Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0
    Registry Value: NTLMMinClientSec
    Recommended Value: 537395200
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.10"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
$RegistryValueName = "NTLMMinClientSec"
$RegistryValueData = 537395200
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult