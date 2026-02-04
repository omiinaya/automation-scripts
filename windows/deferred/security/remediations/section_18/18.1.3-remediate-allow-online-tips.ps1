# Remediation: Allow Online Tips setting on Windows
# CIS Benchmark: 18.1.3 (L2) Ensure 'Allow Online Tips' is set to 'Disabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Set registry value to disable online tips
$remediationBlock = {
    # Invoke remediation using CISRemediation framework
    Invoke-CISRemediation -CIS_ID "18.1.3" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -RegistryValueName "AllowOnlineTips" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
