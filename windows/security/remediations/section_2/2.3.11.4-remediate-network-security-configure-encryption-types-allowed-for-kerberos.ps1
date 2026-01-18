<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.4: Network security: Configure encryption types allowed for Kerberos

.DESCRIPTION
    This script remediates the configuration of 'Network security: Configure encryption types allowed for Kerberos' 
    to set it to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.4-remediate-network-security-configure-encryption-types-allowed-for-kerberos.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.4
    Title: Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters
    Registry Value: SupportedEncryptionTypes
    Recommended Value: 2147483640
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.4"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters"
$RegistryValueName = "SupportedEncryptionTypes"
$RegistryValueData = 2147483640
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult