<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.3: Network Security: Allow PKU2U authentication requests to this computer to use online identities

.DESCRIPTION
    This script audits the configuration of 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' 
    to ensure it is set to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.3-audit-network-security-allow-pku2u-authentication-requests-to-use-online-identities.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.3
    Title: Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\pku2u
    Registry Value: AllowOnlineID
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.3"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u"
$RegistryValueName = "AllowOnlineID"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult