<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Private: Logging: Log successful connections (CIS ID 9.2.7)
.DESCRIPTION
    Audits whether Windows Firewall: Private profile logging of successful connections is set to 'Yes'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.7
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.2.7" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging" -RegistryValueName "LogSuccessfulConnections" -Section "9" -VerboseOutput

# Output the result
return $auditResult