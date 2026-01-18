<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Private: Firewall state (CIS ID 9.2.1)
.DESCRIPTION
    Audits whether Windows Firewall: Private profile firewall state is set to 'On (recommended)'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.1
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.2.1" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile" -RegistryValueName "EnableFirewall" -Section "9" -VerboseOutput

# Output the result
return $auditResult