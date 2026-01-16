<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.2: Network security: Allow LocalSystem NULL session fallback

.DESCRIPTION
    This script audits the configuration of 'Network security: Allow LocalSystem NULL session fallback' 
    to ensure it is set to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.2-audit-network-security-allow-localsystem-null-session-fallback.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.2
    Title: Ensure 'Network security: Allow LocalSystem NULL session fallback' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0
    Registry Value: AllowNullSessionFallback
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.2"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
$RegistryValueName = "AllowNullSessionFallback"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult