<#
.SYNOPSIS
    CIS Remediation Script for 2.2.33 - Ensure 'Perform volume maintenance tasks' is set to 'Administrators'
.DESCRIPTION
    This script remediates the user right assignment for performing volume maintenance tasks.
    The recommended state is: Administrators.
.NOTES
    CIS ID: 2.2.33
    Profile: L1
    File Name: 2.2.33-remediate-perform-volume-maintenance-tasks.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISRemediation.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Create security policy template content
$templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeManageVolumePrivilege = *S-1-5-32-544
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.33" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeManageVolumePrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.33 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Perform volume maintenance tasks' user right has been set to 'Administrators'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.33 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status