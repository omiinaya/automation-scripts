<#
.SYNOPSIS
    CIS Remediation Script for 2.2.29 - Ensure 'Log on as a service' is configured
.DESCRIPTION
    This script remediates the user right assignment for logging on as a service.
    The recommended state is: No One or (when the Hyper-V feature is installed) NT VIRTUAL MACHINE\Virtual Machines or (when using Windows Defender Application Guard) WDAGUtilityAccount.
.NOTES
    CIS ID: 2.2.29
    Profile: L2
    File Name: 2.2.29-remediate-log-on-as-service.ps1
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
SeServiceLogonRight =
"@

# Perform the remediation
$remediationResult = Invoke-CISRemediation -CIS_ID "2.2.29" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeServiceLogonRight" -VerboseOutput

# Output the result
if ($remediationResult.Status -eq "Remediated") {
    Write-Host "CIS 2.2.29 Remediation Result: SUCCESS" -ForegroundColor Green
    Write-Host "The 'Log on as a service' user right has been configured correctly" -ForegroundColor Green
} else {
    Write-Host "CIS 2.2.29 Remediation Result: $($remediationResult.Status)" -ForegroundColor Red
    Write-Host "Message: $($remediationResult.Message)" -ForegroundColor Yellow
    
    if ($remediationResult.RequiresManualAction) {
        Write-Host "Manual action required. Please review the error message above." -ForegroundColor Yellow
    }
}

# Return the remediation status for automated testing
return $remediationResult.Status