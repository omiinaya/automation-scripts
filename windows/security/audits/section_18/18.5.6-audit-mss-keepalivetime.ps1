<#
.SYNOPSIS
    CIS Audit Script for 18.5.6 - Ensure 'MSS: (KeepAliveTime) How often keep-alive packets are sent in milliseconds' is set to 'Enabled: 300,000 or 5 minutes'
.DESCRIPTION
    This script audits the MSS (KeepAliveTime) registry setting to ensure keep-alive packets are sent every 5 minutes.
    The setting checks HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters:KeepAliveTime
.NOTES
    CIS ID: 18.5.6
    Profile: L2
    File Name: 18.5.6-audit-mss-keepalivetime.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.6"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$registryValueName = "KeepAliveTime"

# Custom audit script block for MSS KeepAliveTime checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Convert milliseconds to minutes for readability
                $minutes = [math]::Round($value / 60000, 2)
                $currentSetting = "$value ms ($minutes minutes)"
                
                # Default is 7,200,000 ms (120 minutes)
                # Recommended is 300,000 ms (5 minutes) or less
            } else {
                # Value doesn't exist, which means default (7,200,000 ms = 120 minutes)
                $value = 7200000
                $minutes = 120
                $currentSetting = "$value ms ($minutes minutes) [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 7200000
            $minutes = 120
            $currentSetting = "$value ms ($minutes minutes) [Default - Key Not Found]"
        }
        
        # Determine compliance (must be 300,000 ms or less, which is 5 minutes or less)
        $isCompliant = ($value -le 300000)
        
        return @{
            CurrentValue = $currentSetting
            Source = "Registry"
            Details = "Registry path: $registryPath, Value: $registryValueName, Raw Value: $value ms"
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