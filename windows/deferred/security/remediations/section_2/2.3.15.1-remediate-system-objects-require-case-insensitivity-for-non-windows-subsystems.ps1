<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.15.1: System objects: Require case insensitivity for non-Windows subsystems

.DESCRIPTION
    This script remediates the configuration of 'System objects: Require case insensitivity for non-Windows subsystems' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.15.1-remediate-system-objects-require-case-insensitivity-for-non-windows-subsystems.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.15.1
    Title: Ensure 'System objects: Require case insensitivity for non-Windows subsystems' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel
    Registry Value: ObCaseInsensitive
    Recommended Value: 1
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.15.1"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel"
$RegistryValueName = "ObCaseInsensitive"
$RegistryValueData = 1  # Enabled
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult