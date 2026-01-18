<#
.SYNOPSIS
    Example usage script for CISRemediation module.
.DESCRIPTION
    Demonstrates how to use the CISRemediation module functions with practical examples.
.NOTES
    File Name      : Example-CISRemediationUsage.ps1
    Author         : System Administrator
    Prerequisite   : PowerShell 5.1 or later
#>

# Import required modules
Import-Module "$PSScriptRoot\ModuleIndex.psm1" -Force -WarningAction SilentlyContinue

Write-SectionHeader -Title "CISRemediation Module Usage Examples"

# Example 1: Basic remediation result creation
Write-Host "Example 1: Creating a remediation result object" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$result1 = New-CISRemediationResult -CIS_ID "1.1.1" -Title "Enforce password history" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated password history" -IsCompliant $true -RequiresManualAction $false

Write-Host "CIS ID: $($result1.CIS_ID)" -ForegroundColor White
Write-Host "Title: $($result1.Title)" -ForegroundColor White
Write-Host "Previous Value: $($result1.PreviousValue)" -ForegroundColor White
Write-Host "New Value: $($result1.NewValue)" -ForegroundColor White
Write-Host "Status: $($result1.Status)" -ForegroundColor Green
Write-Host "Is Compliant: $($result1.IsCompliant)" -ForegroundColor White
Write-Host "Requires Manual Action: $($result1.RequiresManualAction)" -ForegroundColor White
Write-Host ""

# Example 2: Domain remediation instructions
Write-Host "Example 2: Domain remediation instructions" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$instructions = Get-DomainRemediationInstructions -CIS_ID "1.1.2" -SettingName "Maximum password age" -RecommendedValue "365 or fewer days, but not 0"

Write-Host "CIS ID: $($instructions.CIS_ID)" -ForegroundColor White
Write-Host "Setting: $($instructions.SettingName)" -ForegroundColor White
Write-Host "Recommended: $($instructions.RecommendedValue)" -ForegroundColor White
Write-Host "Manual Action Required: $($instructions.ManualActionRequired)" -ForegroundColor White
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host $instructions.Instructions -ForegroundColor Gray
Write-Host ""

# Example 3: Security policy template application
Write-Host "Example 3: Security policy template application" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
PasswordHistorySize=24
MaximumPasswordAge=365
MinimumPasswordAge=1
MinimumPasswordLength=14
PasswordComplexity=1
ClearTextPassword=0
"@

Write-Host "Template Content:" -ForegroundColor Yellow
Write-Host $templateContent -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Apply-SecurityPolicyTemplate would be used here" -ForegroundColor White
Write-Host ""

# Example 4: Invoke-CISRemediation usage
Write-Host "Example 4: Invoke-CISRemediation usage" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "Standalone environment remediation:" -ForegroundColor White
Write-Host "-----------------------------------" -ForegroundColor White
Write-Host "$result = Invoke-CISRemediation -CIS_ID \"1.1.1\" -RemediationType \"SecurityPolicy\" -SecurityPolicyTemplate \"[System Access]`nPasswordHistorySize=24\" -SettingName \"PasswordHistorySize\" -VerboseOutput" -ForegroundColor Gray
Write-Host ""

Write-Host "Registry-based remediation:" -ForegroundColor White
Write-Host "---------------------------" -ForegroundColor White
Write-Host "$result = Invoke-CISRemediation -CIS_ID \"2.3.1.1\" -RemediationType \"Registry\" -RegistryPath \"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\" -RegistryValueName \"Start\" -RegistryValueData 4 -RegistryValueType \"DWord\" -VerboseOutput" -ForegroundColor Gray
Write-Host ""

Write-Host "Custom remediation:" -ForegroundColor White
Write-Host "-------------------" -ForegroundColor White
Write-Host "$customScript = {" -ForegroundColor Gray
Write-Host "    # Custom remediation logic here" -ForegroundColor Gray
Write-Host "    return @{" -ForegroundColor Gray
Write-Host "        PreviousValue = \"OldValue\"" -ForegroundColor Gray
Write-Host "        NewValue = \"NewValue\"" -ForegroundColor Gray
Write-Host "    }" -ForegroundColor Gray
Write-Host "}" -ForegroundColor Gray
Write-Host "$result = Invoke-CISRemediation -CIS_ID \"Custom\" -RemediationType \"Custom\" -CustomScriptBlock $customScript -VerboseOutput" -ForegroundColor Gray
Write-Host ""

# Example 5: Exporting remediation results
Write-Host "Example 5: Exporting remediation results" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$remediationResults = @(
    New-CISRemediationResult -CIS_ID "1.1.1" -Title "Enforce password history" -PreviousValue "0" -NewValue "24" -Status "Remediated" -Message "Successfully updated password history" -IsCompliant $true -RequiresManualAction $false,
    New-CISRemediationResult -CIS_ID "1.1.2" -Title "Maximum password age" -PreviousValue "90" -NewValue "365" -Status "Remediated" -Message "Successfully updated maximum password age" -IsCompliant $true -RequiresManualAction $false,
    New-CISRemediationResult -CIS_ID "1.1.3" -Title "Minimum password age" -PreviousValue "0" -NewValue "1" -Status "ManualActionRequired" -Message "Domain environment requires manual action" -IsCompliant $false -RequiresManualAction $true
)

Write-Host "Sample remediation results:" -ForegroundColor Yellow
$remediationResults | Format-Table CIS_ID, Title, Status, IsCompliant, RequiresManualAction -AutoSize
Write-Host ""

Write-Host "Export command:" -ForegroundColor White
Write-Host "Export-CISRemediationResults -Results `$remediationResults -OutputPath \"C:\remediation\results.csv\"" -ForegroundColor Gray
Write-Host ""

# Example 6: Remediation summary
Write-Host "Example 6: Remediation summary" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$summary = Get-CISRemediationSummary -Results $remediationResults

Write-Host "Remediation Summary:" -ForegroundColor Yellow
Write-Host "Total Remediations: $($summary.TotalRemediations)" -ForegroundColor White
Write-Host "Successful Remediations: $($summary.SuccessfulRemediations)" -ForegroundColor White
Write-Host "Manual Action Required: $($summary.ManualActionRequired)" -ForegroundColor White
Write-Host "Failed Remediations: $($summary.FailedRemediations)" -ForegroundColor White
Write-Host "Success Percentage: $($summary.SuccessPercentage)%" -ForegroundColor White
Write-Host "Overall Status: $($summary.OverallStatus)" -ForegroundColor $(if ($summary.OverallStatus -eq "Excellent") { "Green" } else { "Yellow" })
Write-Host ""

Write-Host ""
Write-SectionHeader -Title "CISRemediation Module Usage Summary"
Write-Host "The CISRemediation module provides standardized remediation functions for:" -ForegroundColor Green
Write-Host "• Security policy template application" -ForegroundColor White
Write-Host "• Registry-based remediation" -ForegroundColor White
Write-Host "• Custom remediation scripts" -ForegroundColor White
Write-Host "• Domain environment handling" -ForegroundColor White
Write-Host "• Result tracking and reporting" -ForegroundColor White
Write-Host ""
Write-Host "Use these functions to create consistent, maintainable remediation scripts." -ForegroundColor Green