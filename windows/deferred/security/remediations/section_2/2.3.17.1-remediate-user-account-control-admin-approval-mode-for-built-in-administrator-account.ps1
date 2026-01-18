<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.17.1: User Account Control: Admin Approval Mode for the Built-in Administrator account

.DESCRIPTION
    This script remediates the configuration of 'User Account Control: Admin Approval Mode for the Built-in Administrator account' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.1-remediate-user-account-control-admin-approval-mode-for-built-in-administrator-account.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.17.1
    Title: Ensure 'User Account Control: Admin Approval Mode for the Built-in Administrator account' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: FilterAdministratorToken
    Recommended Value: 1
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.17.1"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "FilterAdministratorToken"
$RegistryValueData = 1  # Enabled
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult