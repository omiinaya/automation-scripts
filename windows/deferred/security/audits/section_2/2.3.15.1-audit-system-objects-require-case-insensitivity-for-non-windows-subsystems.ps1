<#
.SYNOPSIS
    Audit script for CIS ID 2.3.15.1: System objects: Require case insensitivity for non-Windows subsystems

.DESCRIPTION
    This script audits the configuration of 'System objects: Require case insensitivity for non-Windows subsystems' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.15.1-audit-system-objects-require-case-insensitivity-for-non-windows-subsystems.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.15.1
    Title: Ensure 'System objects: Require case insensitivity for non-Windows subsystems' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel
    Registry Value: ObCaseInsensitive
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.15.1"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel"
$RegistryValueName = "ObCaseInsensitive"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult