<#
.SYNOPSIS
    CIS Audit Script for 18.5.4 - Ensure 'MSS: (DisableSavePassword) Prevent the dial-up password from being saved' is set to 'Enabled'
.DESCRIPTION
    This script audits the MSS (DisableSavePassword) registry setting to prevent dial-up passwords from being saved.
    The setting checks HKLM\SYSTEM\CurrentControlSet\Services\RasMan\Parameters:DisableSavePassword
.NOTES
    CIS ID: 18.5.4
    Profile: L2
    File Name: 18.5.4-audit-mss-disablesavepassword.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.4"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters"
$registryValueName = "DisableSavePassword"

# Custom audit script block for MSS DisableSavePassword checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Map numeric values to their meanings
                # 0 = Disabled (Saving of dial-up and VPN passwords is allowed)
                # 1 = Enabled (Prevent dial-up password from being saved)
                
                switch ($value) {
                    0 { $currentSetting = "Disabled" }
                    1 { $currentSetting = "Enabled" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (0 = Disabled)
                $currentSetting = "Disabled"
                $value = "Not Configured (default: 0)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Disabled"
            $value = "Key Not Found (default: 0)"
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