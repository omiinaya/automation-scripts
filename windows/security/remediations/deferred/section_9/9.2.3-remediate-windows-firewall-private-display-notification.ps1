<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Private: Settings: Display a notification (CIS ID 9.2.3)
.DESCRIPTION
    Remediates Windows Firewall: Private profile display notification setting to 'No'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.3
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.2.3" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile" -RegistryValueName "DisableNotifications" -RegistryValueData 1 -RegistryValueType "DWord" -Section "9" -VerboseOutput

# Output the result
return $remediationResult