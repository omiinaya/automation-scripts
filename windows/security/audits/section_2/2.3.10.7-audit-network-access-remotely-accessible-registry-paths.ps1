<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.7: Network access: Remotely accessible registry paths

.DESCRIPTION
    This script audits the configuration of 'Network access: Remotely accessible registry paths' 
    to ensure it is configured with the recommended paths as specified by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.7-audit-network-access-remotely-accessible-registry-paths.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.7
    Title: Ensure 'Network access: Remotely accessible registry paths' is configured
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedExactPaths
    Registry Value: Machine
    Recommended Value: REG_MULTI_SZ with specific paths:
        System\CurrentControlSet\Control\ProductOptions
        System\CurrentControlSet\Control\Server Applications
        Software\Microsoft\Windows NT\CurrentVersion
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.7"
$Title = "Network access: Remotely accessible registry paths"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedExactPaths"
$RegistryValue = "Machine"
$RecommendedValue = @(
    "System\CurrentControlSet\Control\ProductOptions",
    "System\CurrentControlSet\Control\Server Applications", 
    "Software\Microsoft\Windows NT\CurrentVersion"
)
$ValueType = "REG_MULTI_SZ"

# Create audit object
$AuditParams = @{
    CisId = $CisId
    Title = $Title
    RegistryPath = $RegistryPath
    RegistryValue = $RegistryValue
    RecommendedValue = $RecommendedValue
    ValueType = $ValueType
}

# Execute the audit
$AuditResult = Test-CisRegistryCompliance @AuditParams

# Output the result
return $AuditResult