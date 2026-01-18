<#
.SYNOPSIS
    Audit script for CIS ID 2.3.17.4: User Account Control: Detect application installations and prompt for elevation

.DESCRIPTION
    This script audits the configuration of 'User Account Control: Detect application installations and prompt for elevation' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.4-audit-user-account-control-detect-application-installations-prompt-elevation.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.17.4
    Title: Ensure 'User Account Control: Detect application installations and prompt for elevation' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: EnableInstallerDetection
    Recommended Value: 1
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.17.4"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "EnableInstallerDetection"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult