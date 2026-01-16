<#
.SYNOPSIS
    CIS Audit Script for Windows Firewall: Private: Inbound connections (CIS ID 9.2.2)
.DESCRIPTION
    Audits whether Windows Firewall: Private profile inbound connections are set to 'Block (default)'
    according to CIS benchmark recommendations.
.NOTES
    CIS ID: 9.2.2
    Profile: L1
    Section: Windows Firewall
    Version: 4.0.0
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Perform CIS audit
$auditResult = Invoke-CISAudit -CIS_ID "9.2.2" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile" -RegistryValueName "DefaultInboundAction" -Section "9" -VerboseOutput

# Output the result
return $auditResult