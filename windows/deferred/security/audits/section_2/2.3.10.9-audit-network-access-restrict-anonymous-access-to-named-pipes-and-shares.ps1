<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.9: Network access: Restrict anonymous access to Named Pipes and Shares

.DESCRIPTION
    This script audits the configuration of 'Network access: Restrict anonymous access to Named Pipes and Shares' 
    to ensure it is set to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.9-audit-network-access-restrict-anonymous-access-to-named-pipes-and-shares.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.9
    Title: Ensure 'Network access: Restrict anonymous access to Named Pipes and Shares' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters
    Registry Value: RestrictNullSessAccess
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.9"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$RegistryValueName = "RestrictNullSessAccess"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult