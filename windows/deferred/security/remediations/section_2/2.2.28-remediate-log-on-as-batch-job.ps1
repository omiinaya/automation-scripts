<#
.SYNOPSIS
    CIS Remediation Script for 2.2.28 - Ensure 'Log on as a batch job' is set to 'Administrators'
.DESCRIPTION
    This script remediates the user right assignment for logging on as a batch job.
    The recommended state is: Administrators.
.NOTES
    CIS ID: 2.2.28
    Profile: L2
    File Name: 2.2.28-remediate-log-on-as-batch-job.ps1
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
SeBatchLogonRight = *S-1-5-32-544
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.28" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeBatchLogonRight" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.28 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Log on as a batch job' user right has been set to 'Administrators'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.28 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status