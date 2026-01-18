<#
.SYNOPSIS
    CIS Audit Script for 18.5.9 - Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode' is set to 'Enabled'
.DESCRIPTION
    This script audits the MSS (SafeDllSearchMode) registry setting to ensure safe DLL search mode is enabled.
    The setting checks HKLM\SYSTEM\CurrentControlSet\Control\Session Manager:SafeDllSearchMode
.NOTES
    CIS ID: 18.5.9
    Profile: L1
    File Name: 18.5.9-audit-mss-safedllsearchmode.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.9"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$registryValueName = "SafeDllSearchMode"

# Custom audit script block for MSS SafeDllSearchMode checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Map numeric values to their meanings
                # 0 = Disabled (Search current working folder first)
                # 1 = Enabled (Search system path first)
                
                switch ($value) {
                    0 { $currentSetting = "Disabled" }
                    1 { $currentSetting = "Enabled" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (1 = Enabled)
                $currentSetting = "Enabled"
                $value = "Not Configured (default: 1)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Enabled"
            $value = "Key Not Found (default: 1)"
        }
        
        # Determine compliance (must be Enabled = 1)
        $isCompliant = ($currentSetting -eq "Enabled")
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value"
            IsCompliant = $isCompliant
        }
    }
    catch {
        return @{
            CurrentValue = "Error"
            Source = "Registry"
            Details = "Failed to check registry: $_"
            IsCompliant = $false
        }
    }
}

# Invoke the audit using CISFramework
$auditResult = Invoke-CISAudit -CIS_ID $CIS_ID -AuditType "Custom" -CustomScriptBlock $auditScriptBlock -VerboseOutput -Section "18"

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