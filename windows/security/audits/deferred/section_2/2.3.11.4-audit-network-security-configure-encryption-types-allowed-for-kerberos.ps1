<#
.SYNOPSIS
    Audit script for CIS ID 2.3.11.4: Network security: Configure encryption types allowed for Kerberos

.DESCRIPTION
    This script audits the configuration of 'Network security: Configure encryption types allowed for Kerberos' 
    to ensure it is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.4-audit-network-security-configure-encryption-types-allowed-for-kerberos.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.11.4
    Title: Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types'
    Profile: L1
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters
    Registry Value: SupportedEncryptionTypes
    Recommended Value: 2147483640
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.11.4"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters"
$RegistryValueName = "SupportedEncryptionTypes"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult