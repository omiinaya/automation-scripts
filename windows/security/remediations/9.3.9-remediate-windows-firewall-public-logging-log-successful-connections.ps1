<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Public: Logging: Log successful connections (CIS ID 9.3.9)
.DESCRIPTION
    Remediates Windows Firewall: Public profile logging successful connections to set it to 'Yes'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.3.9
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.3.9" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging" -RegistryValueName "LogSuccessfulConnections" -RegistryValueType "DWord" -RegistryValueData "1" -Section "9" -VerboseOutput

# Output the result
return $remediationResult