<#
.SYNOPSIS
    Audit script for CIS ID 2.3.14.1: System cryptography: Force strong key protection for user keys stored on the computer

.DESCRIPTION
    This script audits the configuration of 'System cryptography: Force strong key protection for user keys stored on the computer' 
    to ensure it is set to 'User is prompted when the key is first used' or higher as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.14.1-audit-system-cryptography-force-strong-key-protection-for-user-keys-stored-on-the-computer.ps1

.OUTPUTS
    Returns a custom object with audit results

.NOTES
    CIS ID: 2.3.14.1
    Title: Ensure 'System cryptography: Force strong key protection for user keys stored on the computer' is set to 'User is prompted when the key is first used' or higher
    Profile: L2
    Registry Path: HKLM\SOFTWARE\Policies\Microsoft\Cryptography
    Registry Value: ForceKeyProtection
    Recommended Value: 1 or 2
#>

# Import the CIS Framework module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISFramework.psm1" -Force

# Define audit parameters
$CisId = "2.3.14.1"
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Cryptography"
$RegistryValueName = "ForceKeyProtection"

# Execute the audit using Invoke-CISAudit
$AuditResult = Invoke-CISAudit -CIS_ID $CisId -AuditType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -Section "2" -VerboseOutput

# Output the result
return $AuditResult