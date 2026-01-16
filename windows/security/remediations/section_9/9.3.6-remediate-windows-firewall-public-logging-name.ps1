<#
.SYNOPSIS
    CIS Remediation Script for Windows Firewall: Public: Logging: Name (CIS ID 9.3.6)
.DESCRIPTION
    Remediates Windows Firewall: Public profile logging name to set it to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.3.6
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Perform CIS remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "9.3.6" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging" -RegistryValueName "LogFilePath" -RegistryValueType "String" -RegistryValueData "%SystemRoot%\System32\logfiles\firewall\publicfw.log" -Section "9" -VerboseOutput

# Output the result
return $remediationResult