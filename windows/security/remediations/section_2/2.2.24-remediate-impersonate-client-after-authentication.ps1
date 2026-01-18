<#
.SYNOPSIS
    CIS Remediation Script for 2.2.24 - Ensure 'Impersonate a client after authentication' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE'
.DESCRIPTION
    This script remediates the user right assignment for impersonating a client after authentication.
    The recommended state is: Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE.
.NOTES
    CIS ID: 2.2.24
    Profile: L1
    File Name: 2.2.24-remediate-impersonate-client-after-authentication.ps1
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
SeImpersonatePrivilege = *S-1-5-32-544,*S-1-5-19,*S-1-5-20,*S-1-5-6
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.24" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeImpersonatePrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.24 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Impersonate a client after authentication' user right has been set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.24 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status