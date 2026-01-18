<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.1: Network access: Allow anonymous SID/Name translation

.DESCRIPTION
    This script remediates the configuration of 'Network access: Allow anonymous SID/Name translation' 
    to set it to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.1-remediate-network-access-allow-anonymous-sid-name-translation.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.1
    Title: Ensure 'Network access: Allow anonymous SID/Name translation' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: LsaAnonymousNameLookup
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.1"
$Title = "Network access: Allow anonymous SID/Name translation"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValue = "LsaAnonymousNameLookup"
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