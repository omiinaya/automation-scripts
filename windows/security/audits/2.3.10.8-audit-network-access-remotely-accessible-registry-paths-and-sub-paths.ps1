<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.8: Network access: Remotely accessible registry paths and sub-paths

.DESCRIPTION
    This script audits the configuration of 'Network access: Remotely accessible registry paths and sub-paths' 
    to ensure it is configured with the recommended paths as specified by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.8-audit-network-access-remotely-accessible-registry-paths-and-sub-paths.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.8
    Title: Ensure 'Network access: Remotely accessible registry paths and sub-paths' is configured
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths
    Registry Value: Machine
    Recommended Value: REG_DWORD with specific paths (Note: JSON has discrepancy, using REG_DWORD as specified)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.8"
$Title = "Network access: Remotely accessible registry paths and sub-paths"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths"
$RegistryValue = "Machine"
$RecommendedValue = 1  # Using REG_DWORD as specified in JSON audit procedure
$ValueType = "REG_DWORD"

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