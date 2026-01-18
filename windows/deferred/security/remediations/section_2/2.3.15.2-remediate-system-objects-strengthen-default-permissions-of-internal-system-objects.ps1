<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.15.2: System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)

.DESCRIPTION
    This script remediates the configuration of 'System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.15.2-remediate-system-objects-strengthen-default-permissions-of-internal-system-objects.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.15.2
    Title: Ensure 'System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager
    Registry Value: ProtectionMode
    Recommended Value: 1
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.15.2"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$RegistryValueName = "ProtectionMode"
$RegistryValueData = 1  # Enabled
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult