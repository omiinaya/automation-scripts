<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.11.2: Network security: Allow LocalSystem NULL session fallback

.DESCRIPTION
    This script remediates the configuration of 'Network security: Allow LocalSystem NULL session fallback' 
    to set it to 'Disabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.11.2-remediate-network-security-allow-localsystem-null-session-fallback.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.11.2
    Title: Ensure 'Network security: Allow LocalSystem NULL session fallback' is set to 'Disabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0
    Registry Value: AllowNullSessionFallback
    Recommended Value: 0 (Disabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.11.2"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
$RegistryValueName = "AllowNullSessionFallback"
$RegistryValueData = 0
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult