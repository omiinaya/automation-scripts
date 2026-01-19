<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.17.2: User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode

.DESCRIPTION
    This script remediates the configuration of 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' 
    to set it to 'Prompt for consent on the secure desktop' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.2-remediate-user-account-control-behavior-elevation-prompt-administrators-admin-approval-mode.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.17.2
    Title: Ensure 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' is set to 'Prompt for consent on the secure desktop' or higher
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: ConsentPromptBehaviorAdmin
    Recommended Value: 1 or 2
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.17.2"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "ConsentPromptBehaviorAdmin"
$RegistryValueData = 1  # Prompt for consent on the secure desktop
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult