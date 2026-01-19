<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.3: Network Security: Allow PKU2U authentication requests to this computer to use online identities

.DESCRIPTION
    This script remediates the configuration of 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' 
    to set it to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.3-remediate-network-security-allow-pku2u-authentication-requests-to-use-online-identities.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.3
    Title: Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\pku2u
    Registry Value: AllowOnlineID
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.3"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u"
$RegistryValueName = "AllowOnlineID"
$RegistryValueData = 0
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult