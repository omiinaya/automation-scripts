<#
.SYNOPSIS
    CIS Audit Script for 18.6.7.4 - Ensure 'Enable authentication rate limiter' is set to 'Enabled'
.DESCRIPTION
    This script audits the SMB authentication rate limiter setting to ensure it is enabled.
    The setting checks HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanServer:EnableAuthRateLimiter
.NOTES
    CIS ID: 18.6.7.4
    Profile: L1
    File Name: 18.6.7.4-audit-enable-authentication-rate-limiter.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.6.7.4"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"
$registryValueName = "EnableAuthRateLimiter"

# Custom audit script block for authentication rate limiter checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                $currentSetting = if ($value -eq 1) { "Enabled" } else { "Disabled" }
            } else {
                # Value doesn't exist, which means default (Enabled)
                $value = 1
                $currentSetting = "Enabled [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 1
            $currentSetting = "Enabled [Default - Key Not Found]"
        }
        
        # Determine compliance (must be Enabled - value 1)
        $isCompliant = ($value -eq 1)
        
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