<#
.SYNOPSIS
    CIS Remediation Script for 2.2.27 - Ensure 'Lock pages in memory' is set to 'No One'
.DESCRIPTION
    This script remediates the user right assignment for locking pages in memory.
    The recommended state is: No One.
.NOTES
    CIS ID: 2.2.27
    Profile: L1
    File Name: 2.2.27-remediate-lock-pages-in-memory.ps1
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
SeLockMemoryPrivilege =
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.27" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeLockMemoryPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.27 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Lock pages in memory' user right has been set to 'No One'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.27 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status