<#
.SYNOPSIS
    CIS Audit Script for 17.3.1 - Ensure 'Audit PNP Activity' is set to include 'Success'
.DESCRIPTION
    This script audits the configuration of Audit PNP Activity settings using auditpol.exe.
    It checks if the subcategory is properly configured to include success auditing.
.NOTES
    CIS ID: 17.3.1
    Profile: L1
    File Name: 17.3.1-audit-pnp-activity.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "17.3.1"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "17"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Custom audit script block for auditpol.exe subcategory checking
$auditScriptBlock = {
    try {
        # Run auditpol.exe to get the current configuration
        $auditResult = auditpol /get /subcategory:"{0cce9248-69ae-11d9-bed3-505054503030}"
        
        # Parse the output to extract the current setting
        $currentSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "PNP Activity" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
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
        
        # Determine compliance (must include Success)
        $isCompliant = ($currentSetting -eq "Success" -or $currentSetting -eq "Success and Failure")
        
        return @{
            CurrentValue = $currentSetting
            Source = "auditpol.exe"
            Details = "Subcategory GUID: {0cce9248-69ae-11d9-bed3-505054503030}"
            IsCompliant = $isCompliant
        }
    }
    catch {
        return @{
            CurrentValue = "Error"
            Source = "auditpol.exe"
            Details = "Failed to execute auditpol.exe: $_"
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
    exit 0
} else {
    Write-Host "NON-COMPLIANT: $($auditResult.Title)" -ForegroundColor Red
    Write-Host "Current Value: $($auditResult.CurrentValue)" -ForegroundColor Red
    Write-Host "Recommended: $($auditResult.RecommendedValue)" -ForegroundColor Yellow
    exit 1
}