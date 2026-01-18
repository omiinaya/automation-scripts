<#
.SYNOPSIS
    Audit script for CIS ID 2.3.17.5: User Account Control: Only elevate UIAccess applications that are installed in secure locations

.DESCRIPTION
    This script audits the configuration of 'User Account Control: Only elevate UIAccess applications that are installed in secure locations' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.5-audit-user-account-control-only-elevate-uiaccess-applications-secure-locations.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.17.5
    Title: Ensure 'User Account Control: Only elevate UIAccess applications that are installed in secure locations' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: EnableSecureUIPaths
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.17.5"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "EnableSecureUIPaths"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult