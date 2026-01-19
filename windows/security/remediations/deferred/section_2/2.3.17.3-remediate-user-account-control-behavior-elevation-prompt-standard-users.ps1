<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.17.3: User Account Control: Behavior of the elevation prompt for standard users

.DESCRIPTION
    This script remediates the configuration of 'User Account Control: Behavior of the elevation prompt for standard users' 
    to set it to 'Automatically deny elevation requests' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.3-remediate-user-account-control-behavior-elevation-prompt-standard-users.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.17.3
    Title: Ensure 'User Account Control: Behavior of the elevation prompt for standard users' is set to 'Automatically deny elevation requests'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: ConsentPromptBehaviorUser
    Recommended Value: 0
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.17.3"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "ConsentPromptBehaviorUser"
$RegistryValueData = 0  # Automatically deny elevation requests
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult