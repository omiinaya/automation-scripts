<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.11: Network access: Shares that can be accessed anonymously

.DESCRIPTION
    This script audits the configuration of 'Network access: Shares that can be accessed anonymously' 
    to ensure it is set to 'None' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.11-audit-network-access-shares-that-can-be-accessed-anonymously.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.11
    Title: Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters
    Registry Value: NullSessionShares
    Recommended Value: <blank> (None)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.11"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$RegistryValueName = "NullSessionShares"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult