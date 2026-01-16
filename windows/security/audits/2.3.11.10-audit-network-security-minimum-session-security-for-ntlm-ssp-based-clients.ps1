<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.10: Network security: Minimum session security for NTLM SSP based (including secure RPC) clients

.DESCRIPTION
    This script audits the configuration of 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' 
    to ensure it is set to 'Require NTLMv2 session security, Require 128-bit encryption' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.10-audit-network-security-minimum-session-security-for-ntlm-ssp-based-clients.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.10
    Title: Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0
    Registry Value: NTLMMinClientSec
    Recommended Value: 537395200
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.10"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
$RegistryValueName = "NTLMMinClientSec"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult