<#
.SYNOPSIS
    CIS Remediation Script for 2.2.25 - Ensure 'Increase scheduling priority' is set to 'Administrators, Window Manager\Window Manager Group'
.DESCRIPTION
    This script remediates the user right assignment for increasing scheduling priority.
    The recommended state is: Administrators, Window Manager\Window Manager Group.
.NOTES
    CIS ID: 2.2.25
    Profile: L1
    File Name: 2.2.25-remediate-increase-scheduling-priority.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISRemediation.psm1
#>

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISRemediation.psm1" -Force

# Create security policy template content
$templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeIncreaseBasePriorityPrivilege = *S-1-5-32-544,*S-1-5-90-0
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.25" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeIncreaseBasePriorityPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.25 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Increase scheduling priority' user right has been set to 'Administrators, Window Manager\Window Manager Group'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.25 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status