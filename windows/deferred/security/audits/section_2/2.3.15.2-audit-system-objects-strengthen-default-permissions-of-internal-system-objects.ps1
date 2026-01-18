<#
.SYNOPSIS
    Audit script for CIS ID 2.3.15.2: System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)

.DESCRIPTION
    This script audits the configuration of 'System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.15.2-audit-system-objects-strengthen-default-permissions-of-internal-system-objects.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.15.2
    Title: Ensure 'System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager
    Registry Value: ProtectionMode
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.15.2"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$RegistryValueName = "ProtectionMode"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult