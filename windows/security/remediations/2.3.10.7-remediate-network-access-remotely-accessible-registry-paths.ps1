<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.7: Network access: Remotely accessible registry paths

.DESCRIPTION
    This script remediates the configuration of 'Network access: Remotely accessible registry paths' 
    to set it with the recommended paths as specified by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.7-remediate-network-access-remotely-accessible-registry-paths.ps1

.OUTPUTS
    Returns a custom object with remediation results

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

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
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