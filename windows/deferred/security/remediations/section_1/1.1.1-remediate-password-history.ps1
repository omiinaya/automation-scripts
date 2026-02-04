# Remediation: Enforce password history setting on Windows
# CIS Benchmark: 1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Create security policy template for password history
$remediationBlock = {
    # Create security policy template with PasswordHistorySize=24
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
PasswordHistorySize=24
"@
    
    # Invoke remediation using CISRemediation framework
    Invoke-CISRemediation -CIS_ID "1.1.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "PasswordHistorySize" -VerboseOutput:$VerboseOutput
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
