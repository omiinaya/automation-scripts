<#
.SYNOPSIS
    CIS Audit Script for 18.5.8 - Ensure 'MSS: (PerformRouterDiscovery) Allow IRDP to detect and configure Default Gateway addresses' is set to 'Disabled'
.DESCRIPTION
    This script audits the MSS (PerformRouterDiscovery) registry setting to ensure IRDP is disabled.
    The setting checks HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters:PerformRouterDiscovery
.NOTES
    CIS ID: 18.5.8
    Profile: L2
    File Name: 18.5.8-audit-mss-performrouterdiscovery.ps1
    Author: System Administrator
    Prerequisite: PowerShell 5.1 or later
    Dependencies: CISFramework.psm1
#> 

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force -WarningAction SilentlyContinue

# CIS ID for this audit
$CIS_ID = "18.5.8"

# Get CIS recommendation
$recommendation = Get-CISRecommendation -CIS_ID $CIS_ID -Section "18"

if (-not $recommendation) {
    Write-Error "CIS recommendation for $CIS_ID not found"
    exit 1
}

# Registry path and value name from CIS documentation
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$registryValueName = "PerformRouterDiscovery"

# Custom audit script block for MSS PerformRouterDiscovery checking
$auditScriptBlock = {
    try {
        # Check if registry key exists
        if (Test-Path $registryPath) {
            # Get the current value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
            
            if ($currentValue) {
                $value = $currentValue.$registryValueName
                
                # Map numeric values to their meanings
                # 0 = Disabled (IRDP disabled)
                # 1 = Enabled (IRDP enabled)
                # 2 = Enable only if DHCP sends the Perform Router Discovery option
                
                switch ($value) {
                    0 { $currentSetting = "Disabled" }
                    1 { $currentSetting = "Enabled" }
                    2 { $currentSetting = "Enabled only if DHCP sends option" }
                    default { $currentSetting = "Unknown ($value)" }
                }
            } else {
                # Value doesn't exist, which means default (2 = Enable only if DHCP sends option)
                $currentSetting = "Enabled only if DHCP sends option"
                $value = "Not Configured (default: 2)"
            }
        } else {
            # Key doesn't exist, which means default behavior
            $currentSetting = "Enabled only if DHCP sends option"
            $value = "Key Not Found (default: 2)"
        }
        
        # Determine compliance (must be Disabled = 0)
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