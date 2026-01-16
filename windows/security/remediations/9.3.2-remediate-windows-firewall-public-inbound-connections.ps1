<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Public: Inbound connections (CIS ID 9.3.2)
.DESCRIPTION
    Remediates Windows Firewall: Public profile inbound connections to 'Block (default)'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.3.2
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.3.2" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile" -RegistryValueName "DefaultInboundAction" -RegistryValueData 1 -RegistryValueType "DWord" -Section "9" -VerboseOutput

# Output the result
return $remediationResult