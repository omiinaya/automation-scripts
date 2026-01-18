<#
.SYNOPSIS
    CIS Audit Script for 18.6.4.2 - Ensure 'Turn off default IPv6 DNS Servers' is set to 'Enabled'
.DESCRIPTION
    This script audits the default IPv6 DNS Servers setting to ensure it is enabled.
    The setting checks HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient:DisableIPv6DefaultDnsServers
.NOTES
    CIS ID: 18.6.4.2
    Profile: L2
    File Name: 18.6.4.2-audit-turn-off-default-ipv6-dns-servers.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.6.4.2"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
$registryValueName = "DisableIPv6DefaultDnsServers"

# Custom audit script block for IPv6 DNS Servers checking
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
                # Value doesn't exist, which means default (Disabled)
                $value = 0
                $currentSetting = "Disabled [Default]"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $value = 0
            $currentSetting = "Disabled [Default - Key Not Found]"
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