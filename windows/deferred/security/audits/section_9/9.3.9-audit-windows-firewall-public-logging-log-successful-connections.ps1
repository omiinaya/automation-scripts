<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Public: Logging: Log successful connections (CIS ID 9.3.9)
.DESCRIPTION
    Audits whether Windows Firewall: Public profile logging successful connections is set to 'Yes'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.3.9
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.3.9" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging" -RegistryValueName "LogSuccessfulConnections" -Section "9" -VerboseOutput

# Output the result
return $auditResult