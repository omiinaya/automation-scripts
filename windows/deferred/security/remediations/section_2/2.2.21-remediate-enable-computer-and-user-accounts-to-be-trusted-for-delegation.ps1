<#
.SYNOPSIS
    CIS Remediation Script for 2.2.21 - Ensure 'Enable computer and user accounts to be trusted for delegation' is set to 'No One'
.DESCRIPTION
    This script remediates the user right assignment for enabling computer and user accounts to be trusted for delegation.
    The recommended state is: No One.
.NOTES
    CIS ID: 2.2.21
    Profile: L1
    File Name: 2.2.21-remediate-enable-computer-and-user-accounts-to-be-trusted-for-delegation.ps1
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
SeEnableDelegationPrivilege =
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.21" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeEnableDelegationPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.21 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Enable computer and user accounts to be trusted for delegation' user right has been set to 'No One'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.21 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status