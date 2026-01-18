<#
.SYNOPSIS
    Audit script for CIS ID 2.3.10.10: Network access: Restrict clients allowed to make remote calls to SAM

.DESCRIPTION
    This script audits the configuration of 'Network access: Restrict clients allowed to make remote calls to SAM' 
    to ensure it is set to 'Administrators: Remote Access: Allow' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.10-audit-network-access-restrict-clients-allowed-to-make-remote-calls-to-sam.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.10.10
    Title: Ensure 'Network access: Restrict clients allowed to make remote calls to SAM' is set to 'Administrators: Remote Access: Allow'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa
    Registry Value: restrictremotesam
    Recommended Value: O:BAG:BAD:(A;;RC;;;BA) (Administrators: Remote Access: Allow)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.10.10"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$RegistryValueName = "restrictremotesam"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult