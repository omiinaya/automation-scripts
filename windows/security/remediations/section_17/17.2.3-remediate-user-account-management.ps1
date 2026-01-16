<#
.SYNOPSIS
    CIS Remediation Script for 17.2.3 - Ensure 'Audit User Account Management' is set to 'Success and Failure'
.DESCRIPTION
    This script remediates the configuration of Audit User Account Management settings using auditpol.exe.
    It configures the subcategory for both success and failure auditing.
.NOTES
    CIS ID: 17.2.3
    Profile: L1
    File Name: 17.2.3-remediate-user-account-management.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISRemediation.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this remediation
$CIS_ID = "17.2.3"

# Custom remediation script block for auditpol.exe subcategory configuration
$remediationScriptBlock = {
    try {
        # Get current setting first
        $auditResult = auditpol /get /subcategory:"{0cce9235-69ae-11d9-bed3-505054503030}"
        $previousSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "User Account Management" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                if ($line -match "Success and Failure") {
                    $previousSetting = "Success and Failure"
                } elseif ($line -match "Success") {
                    $previousSetting = "Success"
                } elseif ($line -match "Failure") {
                    $previousSetting = "Failure"
                } elseif ($line -match "No Auditing") {
                    $previousSetting = "No Auditing"
                }
                break
            }
        }
        
        # Set the audit policy to Success and Failure
        $setResult = auditpol /set /subcategory:"{0cce9235-69ae-11d9-bed3-505054503030}" /success:enable /failure:enable
        
        if ($LASTEXITCODE -eq 0) {
            # Verify the change
            Start-Sleep -Seconds 2
            $verifyResult = auditpol /get /subcategory:"{0cce9235-69ae-11d9-bed3-505054503030}"
            $newSetting = "Unknown"
            foreach ($line in $verifyResult) {
                if ($line -match "User Account Management" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                    if ($line -match "Success and Failure") {
                        $newSetting = "Success and Failure"
                    }
                    break
                }
            }
            
            return @{
                PreviousValue = $previousSetting
                NewValue = $newSetting
                IsCompliant = ($newSetting -eq "Success and Failure")
            }
        } else {
            return @{
                PreviousValue = $previousSetting
                NewValue = "Failed to set"
                IsCompliant = $false
            }
        }
    }
    catch {
        return @{
            PreviousValue = "Error"
            NewValue = "Error"
            IsCompliant = $false
        }
    }
}

# Invoke the remediation using CISRemediation
$remediationResult = Invoke-CISRemediation -CIS_ID $CIS_ID -RemediationType "Custom" -CustomScriptBlock $remediationScriptBlock -VerboseOutput

# Output the result
if ($remediationResult.IsCompliant) {
    Write-Host "SUCCESS: $($remediationResult.Title)" -ForegroundColor Green
    Write-Host "Previous Value: $($remediationResult.PreviousValue)" -ForegroundColor Yellow
    Write-Host "New Value: $($remediationResult.NewValue)" -ForegroundColor Green
    Write-Host "Status: $($remediationResult.Status)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAILED: $($remediationResult.Title)" -ForegroundColor Red
    Write-Host "Previous Value: $($remediationResult.PreviousValue)" -ForegroundColor Yellow
    Write-Host "New Value: $($remediationResult.NewValue)" -ForegroundColor Red
    Write-Host "Status: $($remediationResult.Status)" -ForegroundColor Red
    if ($remediationResult.ErrorMessage) {
        Write-Host "Error: $($remediationResult.ErrorMessage)" -ForegroundColor Red
    }
    exit 1
}