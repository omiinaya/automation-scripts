<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Public: Settings: Display a notification (CIS ID 9.3.3)
.DESCRIPTION
    Audits whether Windows Firewall: Public profile display notification setting is set to 'No'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.3.3
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.3.3" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile" -RegistryValueName "DisableNotifications" -Section "9" -VerboseOutput

# Output the result
return $auditResult