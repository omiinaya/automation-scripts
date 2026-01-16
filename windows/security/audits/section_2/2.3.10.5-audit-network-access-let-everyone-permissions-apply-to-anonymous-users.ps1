<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.5: Network access: Let Everyone permissions apply to anonymous users

.DESCRIPTION
    This script audits the configuration of 'Network access: Let Everyone permissions apply to anonymous users' 
    to ensure it is set to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.5-audit-network-access-let-everyone-permissions-apply-to-anonymous-users.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.5
    Title: Ensure 'Network access: Let Everyone permissions apply to anonymous users' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: EveryoneIncludesAnonymous
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.5"
$Title = "Network access: Let Everyone permissions apply to anonymous users"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValue = "EveryoneIncludesAnonymous"
$RecommendedValue = 0
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