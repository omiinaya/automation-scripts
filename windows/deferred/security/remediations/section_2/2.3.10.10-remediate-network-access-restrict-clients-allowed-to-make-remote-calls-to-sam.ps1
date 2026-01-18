<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.10: Network access: Restrict clients allowed to make remote calls to SAM

.DESCRIPTION
    This script remediates the configuration of 'Network access: Restrict clients allowed to make remote calls to SAM' 
    to set it to 'Administrators: Remote Access: Allow' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.10-remediate-network-access-restrict-clients-allowed-to-make-remote-calls-to-sam.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.10
    Title: Ensure 'Network access: Restrict clients allowed to make remote calls to SAM' is set to 'Administrators: Remote Access: Allow'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: restrictremotesam
    Recommended Value: O:BAG:BAD:(A;;RC;;;BA) (Administrators: Remote Access: Allow)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.10"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "restrictremotesam"
$RegistryValueData = "O:BAG:BAD:(A;;RC;;;BA)"
$RegistryValueType = "String"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult