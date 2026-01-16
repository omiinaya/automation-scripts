<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Private: Logging: Size limit (KB) (CIS ID 9.2.5)
.DESCRIPTION
    Audits whether Windows Firewall: Private profile logging size limit is set to '16,384 KB or greater'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.5
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.2.5" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogFileSize" -Section "9" -VerboseOutput

# Output the result
return $auditResult