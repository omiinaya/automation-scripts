<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Private: Logging: Size limit (KB) (CIS ID 9.2.5)
.DESCRIPTION
    Remediates Windows Firewall: Private profile logging size limit to '16,384 KB or greater'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.5
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.2.5" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogFileSize" -RegistryValueData 16384 -RegistryValueType "DWord" -Section "9" -VerboseOutput

# Output the result
return $remediationResult