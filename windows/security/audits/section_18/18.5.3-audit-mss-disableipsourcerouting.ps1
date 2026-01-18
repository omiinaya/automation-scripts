<#
.SYNOPSIS
    CIS Audit Script for 18.5.3 - Ensure 'MSS: (DisableIPSourceRouting) IP source routing protection level' is set to 'Enabled: Highest protection, source routing is completely disabled'
.DESCRIPTION
    This script audits the MSS (DisableIPSourceRouting) registry setting to ensure IP source routing protection is at highest level.
    The setting checks HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters:DisableIPSourceRouting
.NOTES
    CIS ID: 18.5.3
    Profile: L1
    File Name: 18.5.3-audit-mss-disableipsourcerouting.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.3"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$registryValueName = "DisableIPSourceRouting"

# Custom audit script block for MSS DisableIPSourceRouting checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Map numeric values to their meanings
                # 0 = No additional protection, source routed packets are allowed
                # 1 = Medium, source routed packets ignored when IP forwarding is enabled
                # 2 = Highest protection, source routing is completely disabled
                
                switch ($value) {
                    0 { $currentSetting = "No protection" }
                    1 { $currentSetting = "Medium protection" }
                    2 { $currentSetting = "Highest protection" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (1 = Medium protection)
                $currentSetting = "Medium protection"
                $value = "Not Configured (default: 1)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Medium protection"
            $value = "Key Not Found (default: 1)"
        }
        
        # Determine compliance (must be Highest protection = 2)
        $isCompliant = ($currentSetting -eq "Highest protection")
        
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