<#
.SYNOPSIS
    CIS Audit Script for 17.5.4 - Ensure 'Audit Logon' is set to 'Success and Failure'
.DESCRIPTION
    This script audits the configuration of Audit Logon settings using auditpol.exe.
    It checks if the subcategory is set to Success and Failure auditing.
.NOTES
    CIS ID: 17.5.4
    Profile: L1
    File Name: 17.5.4-audit-logon.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "17.5.4"

# Custom audit script block for auditpol.exe subcategory configuration
$auditScriptBlock = {
    try {
        # Get current audit policy setting for Logon subcategory
        $auditResult = auditpol /get /subcategory:"{0cce9215-69ae-11d9-bed3-505054503030}"
        $currentSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "Logon" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                if ($line -match "Success and Failure") {
                    $currentSetting = "Success and Failure"
                } elseif ($line -match "Success") {
                    $currentSetting = "Success"
                } elseif ($line -match "Failure") {
                    $currentSetting = "Failure"
                } elseif ($line -match "No Auditing") {
                    $currentSetting = "No Auditing"
                }
                break
            }
        }
        
        # Check compliance: must be set to Success and Failure
        $isCompliant = ($currentSetting -eq "Success and Failure")
        
        return @{
            CurrentValue = $currentSetting
            Source = "auditpol.exe"
            Details = "Subcategory GUID: {0cce9215-69ae-11d9-bed3-505054503030}"
            IsCompliant = $isCompliant
        }
    }
    catch {
        return @{
            CurrentValue = "Error"
            Source = "auditpol.exe"
            Details = "Failed to retrieve audit policy"
            IsCompliant = $false
        }
    }
}

# Invoke the audit using CISFramework
$auditResult = Invoke-CISAudit -CIS_ID $CIS_ID -AuditType "Custom" -CustomScriptBlock $auditScriptBlock -VerboseOutput

# Output the result
if ($auditResult.IsCompliant) {
    Write-Host "COMPLIANT: $($auditResult.Title)" -ForegroundColor Green
    Write-Host "Current Value: $($auditResult.CurrentValue)" -ForegroundColor Green
    Write-Host "Source: $($auditResult.Source)" -ForegroundColor Cyan
    Write-Host "Details: $($auditResult.Details)" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "NON-COMPLIANT: $($auditResult.Title)" -ForegroundColor Red
    Write-Host "Current Value: $($auditResult.CurrentValue)" -ForegroundColor Red
    Write-Host "Source: $($auditResult.Source)" -ForegroundColor Cyan
    Write-Host "Details: $($auditResult.Details)" -ForegroundColor Cyan
    exit 1
}