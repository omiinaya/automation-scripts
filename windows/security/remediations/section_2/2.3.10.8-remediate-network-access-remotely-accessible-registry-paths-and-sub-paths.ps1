<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.8: Network access: Remotely accessible registry paths and sub-paths

.DESCRIPTION
    This script remediates the configuration of 'Network access: Remotely accessible registry paths and sub-paths' 
    to set it with the recommended paths as specified by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.8-remediate-network-access-remotely-accessible-registry-paths-and-sub-paths.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.8
    Title: Ensure 'Network access: Remotely accessible registry paths and sub-paths' is configured
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths
    Registry Value: Machine
    Recommended Value: REG_DWORD with specific paths (Note: JSON has discrepancy, using REG_DWORD as specified)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.8"
$Title = "Network access: Remotely accessible registry paths and sub-paths"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths"
$RegistryValue = "Machine"
$RecommendedValue = 1  # Using REG_DWORD as specified in JSON audit procedure
$ValueType = "REG_DWORD"

# Create remediation object
$RemediationParams = @{
    CisId = $CisId
    Title = $Title
    RegistryPath = $RegistryPath
    RegistryValue = $RegistryValue
    RecommendedValue = $RecommendedValue
    ValueType = $ValueType
}

# Execute the remediation
$RemediationResult = Set-CisRegistryValue @RemediationParams

# Output the result
return $RemediationResult