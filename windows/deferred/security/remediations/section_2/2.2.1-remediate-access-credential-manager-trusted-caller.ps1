# Remediation: Access Credential Manager as a trusted caller setting on Windows
# CIS Benchmark: 2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Create security policy template for user rights assignment
$remediationBlock = {
    # Create security policy template with empty privilege (No One)
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeTrustedCredManAccessPrivilege =
"@
    
    # Invoke remediation using CISRemediation framework
    Invoke-CISRemediation -CIS_ID "2.2.1" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeTrustedCredManAccessPrivilege" -VerboseOutput:$VerboseOutput
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
