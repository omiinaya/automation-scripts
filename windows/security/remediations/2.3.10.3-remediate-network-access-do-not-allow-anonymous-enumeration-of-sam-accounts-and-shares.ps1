<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.3: Network access: Do not allow anonymous enumeration of SAM accounts and shares

.DESCRIPTION
    This script remediates the configuration of 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.3-remediate-network-access-do-not-allow-anonymous-enumeration-of-sam-accounts-and-shares.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.3
    Title: Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: RestrictAnonymous
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.3"
$Title = "Network access: Do not allow anonymous enumeration of SAM accounts and shares"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValue = "RestrictAnonymous"
$RecommendedValue = 1
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