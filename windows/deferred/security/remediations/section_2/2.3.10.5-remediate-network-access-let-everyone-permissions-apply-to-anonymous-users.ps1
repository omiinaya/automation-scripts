<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.5: Network access: Let Everyone permissions apply to anonymous users

.DESCRIPTION
    This script remediates the configuration of 'Network access: Let Everyone permissions apply to anonymous users' 
    to set it to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.5-remediate-network-access-let-everyone-permissions-apply-to-anonymous-users.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.5
    Title: Ensure 'Network access: Let Everyone permissions apply to anonymous users' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: EveryoneIncludesAnonymous
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.5"
$Title = "Network access: Let Everyone permissions apply to anonymous users"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValue = "EveryoneIncludesAnonymous"
$RecommendedValue = 0
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