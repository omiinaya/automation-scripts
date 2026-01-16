<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.14.1: System cryptography: Force strong key protection for user keys stored on the computer

.DESCRIPTION
    This script remediates the configuration of 'System cryptography: Force strong key protection for user keys stored on the computer' 
    to set it to 'User is prompted when the key is first used' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.14.1-remediate-system-cryptography-force-strong-key-protection-for-user-keys-stored-on-the-computer.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.14.1
    Title: Ensure 'System cryptography: Force strong key protection for user keys stored on the computer' is set to 'User is prompted when the key is first used' or higher
    Profile: L2
    Registry Path: HKLM\SOFTWARE\Policies\Microsoft\Cryptography
    Registry Value: ForceKeyProtection
    Recommended Value: 1 or 2
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.14.1"
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Cryptography"
$RegistryValueName = "ForceKeyProtection"
$RegistryValueData = 1  # User is prompted when the key is first used
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult