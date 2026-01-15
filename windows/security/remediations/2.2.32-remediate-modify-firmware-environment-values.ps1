<#
.SYNOPSIS
    CIS Remediation Script for 2.2.32 - Ensure 'Modify firmware environment values' is set to 'Administrators'
.DESCRIPTION
    This script remediates the user right assignment for modifying firmware environment values.
    The recommended state is: Administrators.
.NOTES
    CIS ID: 2.2.32
    Profile: L1
    File Name: 2.2.32-remediate-modify-firmware-environment-values.ps1
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
SeSystemEnvironmentPrivilege = *S-1-5-32-544
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.32" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeSystemEnvironmentPrivilege" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.32 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Modify firmware environment values' user right has been set to 'Administrators'" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.32 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status