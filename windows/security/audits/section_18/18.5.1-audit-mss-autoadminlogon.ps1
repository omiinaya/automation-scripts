<#
.SYNOPSIS
    CIS Audit Script for 18.5.1 - Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon' is set to 'Disabled'
.DESCRIPTION
    This script audits the MSS (AutoAdminLogon) registry setting to ensure automatic logon is disabled.
    The setting checks HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon:AutoAdminLogon
.NOTES
    CIS ID: 18.5.1
    Profile: L1
    File Name: 18.5.1-audit-mss-autoadminlogon.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.1"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$registryValueName = "AutoAdminLogon"

# Custom audit script block for MSS AutoAdminLogon checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Convert to string for comparison
                if ($value -eq "0") {
                    $currentSetting = "Disabled"
                } elseif ($value -eq "1") {
                    $currentSetting = "Enabled"
                } else {
                    $currentSetting = $value.ToString()
                }
            } else {
                # Value doesn't exist, which means it's not configured (default is Disabled)
                $currentSetting = "Disabled"
                $value = "Not Configured"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Disabled"
            $value = "Key Not Found"
        }
        
        # Determine compliance (must be Disabled)
        $isCompliant = ($currentSetting -eq "Disabled")
        
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