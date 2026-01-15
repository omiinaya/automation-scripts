<#
.SYNOPSIS
    CIS Remediation Script for 2.2.30 - Ensure 'Manage auditing and security log' is set to 'Administrators'
.DESCRIPTION
    This script remediates the user right assignment for managing auditing and security log.
    The recommended state is: Administrators.
.NOTES
    CIS ID: 2.2.30
    Profile: L1
    File Name: 2.2.30-remediate-manage-auditing-and-security-log.ps1
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
SeSecurityPrivilege = *S-1-5-32-544
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.30" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeSecurityPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.30 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Manage auditing and security log' user right has been set to 'Administrators'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.30 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status