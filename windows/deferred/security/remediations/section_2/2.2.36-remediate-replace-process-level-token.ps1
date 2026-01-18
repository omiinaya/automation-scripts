<#
.SYNOPSIS
    CIS Remediation Script for 2.2.36 - Ensure 'Replace a process level token' is set to 'LOCAL SERVICE, NETWORK SERVICE'
.DESCRIPTION
    This script remediates the user right assignment for replacing process level tokens.
    The recommended state is: LOCAL SERVICE, NETWORK SERVICE.
.NOTES
    CIS ID: 2.2.36
    Profile: L1
    File Name: 2.2.36-remediate-replace-process-level-token.ps1
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
SeAssignPrimaryTokenPrivilege = *S-1-5-19,*S-1-5-20
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.36" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeAssignPrimaryTokenPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.36 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Replace a process level token' user right has been set to 'LOCAL SERVICE, NETWORK SERVICE'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.36 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status