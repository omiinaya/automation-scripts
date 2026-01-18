<#
.SYNOPSIS
    Remediation script for CIS ID 2.3.10.9: Network access: Restrict anonymous access to Named Pipes and Shares

.DESCRIPTION
    This script remediates the configuration of 'Network access: Restrict anonymous access to Named Pipes and Shares' 
    to set it to 'Enabled' as recommended by CIS Benchmark.

.PARAMETER None
    This script does not accept parameters.

.EXAMPLE
    .\2.3.10.9-remediate-network-access-restrict-anonymous-access-to-named-pipes-and-shares.ps1

.OUTPUTS
    Returns a custom object with remediation results

.NOTES
    CIS ID: 2.3.10.9
    Title: Ensure 'Network access: Restrict anonymous access to Named Pipes and Shares' is set to 'Enabled'
    Profile: L1
    Registry Path: HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters
    Registry Value: RestrictNullSessAccess
    Recommended Value: 1 (Enabled)
#>

# Import the CIS Remediation module
Import-Module -Name "$PSScriptRoot\..\..\modules\CISRemediation.psm1" -Force

# Define remediation parameters
$CisId = "2.3.10.9"
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters"
$RegistryValueName = "RestrictNullSessAccess"
$RegistryValueData = 1
$RegistryValueType = "DWord"

# Execute the remediation using Invoke-CISRemediation
$RemediationResult = Invoke-CISRemediation -CIS_ID $CisId -RemediationType "Registry" -RegistryPath $RegistryPath -RegistryValueName $RegistryValueName -RegistryValueData $RegistryValueData -RegistryValueType $RegistryValueType -Section "2" -VerboseOutput

# Output the result
return $RemediationResult