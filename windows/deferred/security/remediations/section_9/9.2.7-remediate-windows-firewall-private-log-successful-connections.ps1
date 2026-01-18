<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Private: Logging: Log successful connections (CIS ID 9.2.7)
.DESCRIPTION
    Remediates Windows Firewall: Private profile logging of successful connections to 'Yes'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.7
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.2.7" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogSuccessfulConnections" -RegistryValueData 1 -RegistryValueType "DWord" -Section "9" -VerboseOutput

# Output the result
return $remediationResult