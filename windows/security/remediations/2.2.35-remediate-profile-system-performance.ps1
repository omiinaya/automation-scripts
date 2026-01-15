<#
.SYNOPSIS
    CIS Remediation Script for 2.2.35 - Ensure 'Profile system performance' is set to 'Administrators, NT SERVICE\WdiServiceHost'
.DESCRIPTION
    This script remediates the user right assignment for profiling system performance.
    The recommended state is: Administrators, NT SERVICE\WdiServiceHost.
.NOTES
    CIS ID: 2.2.35
    Profile: L1
    File Name: 2.2.35-remediate-profile-system-performance.ps1
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
SeSystemProfilePrivilege = *S-1-5-32-544,*S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.35" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeSystemProfilePrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.35 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Profile system performance' user right has been set to 'Administrators, NT SERVICE\WdiServiceHost'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.35 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status