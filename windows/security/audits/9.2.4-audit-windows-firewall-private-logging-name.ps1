<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Private: Logging: Name (CIS ID 9.2.4)
.DESCRIPTION
    Audits whether Windows Firewall: Private profile logging name is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.4
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.2.4" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogFilePath" -Section "9" -VerboseOutput

# Output the result
return $auditResult