<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Private: Logging: Name (CIS ID 9.2.4)
.DESCRIPTION
    Remediates Windows Firewall: Private profile logging name to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.4
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.2.4" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogFilePath" -RegistryValueData "%SystemRoot%\System32\logfiles\firewall\privatefw.log" -RegistryValueType "String" -Section "9" -VerboseOutput

# Output the result
return $remediationResult