<#
.SYNOPSIS
    Audit script for CIS ID 2.3.17.2: User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode

.DESCRIPTION
    This script audits the configuration of 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' 
    to ensure it is set to 'Prompt for consent on the secure desktop' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.17.2-audit-user-account-control-behavior-elevation-prompt-administrators-admin-approval-mode.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.17.2
    Title: Ensure 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' is set to 'Prompt for consent on the secure desktop' or higher
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    Registry Value: ConsentPromptBehaviorAdmin
    Recommended Value: 1 or 2
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.17.2"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryValueName = "ConsentPromptBehaviorAdmin"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult