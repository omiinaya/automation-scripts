<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.6: Network access: Named Pipes that can be accessed anonymously

.DESCRIPTION
    This script audits the configuration of 'Network access: Named Pipes that can be accessed anonymously' 
    to ensure it is set to 'None' (blank) as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.6-audit-network-access-named-pipes-that-can-be-accessed-anonymously.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.6
    Title: Ensure 'Network access: Named Pipes that can be accessed anonymously' is set to 'None'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters
    Registry Value: NullSessionPipes
    Recommended Value: Blank/None (REG_MULTI_SZ with no value)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.6"
$Title = "Network access: Named Pipes that can be accessed anonymously"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$RegistryValue = "NullSessionPipes"
$RecommendedValue = @()  # Empty array for REG_MULTI_SZ
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