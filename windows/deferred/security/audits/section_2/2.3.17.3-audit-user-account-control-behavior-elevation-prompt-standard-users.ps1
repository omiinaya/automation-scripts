<#
.SYNOPSIS
    Audit script for CIS ID 2.3.17.3: User Account Control: Behavior of the elevation prompt for standard users

.DESCRIPTION
    This script audits the configuration of 'User Account Control: Behavior of the elevation prompt for standard users' 
    to ensure it is set to 'Automatically deny elevation requests' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.3-audit-user-account-control-behavior-elevation-prompt-standard-users.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.17.3
    Title: Ensure 'User Account Control: Behavior of the elevation prompt for standard users' is set to 'Automatically deny elevation requests'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: ConsentPromptBehaviorUser
    Recommended Value: 0
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.17.3"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "ConsentPromptBehaviorUser"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult