# Remediation: 2.2.14
# CIS Benchmark: 2.2.14 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "User Rights Assignment Remediation: Create symbolic links"
    }
    
    # Create security policy template
    $templateContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeCreateSymbolicLinkPrivilege = *S-1-5-32-544
"@
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "2.2.14" -RemediationType "SecurityPolicy" -SecurityPolicyTemplate $templateContent -SettingName "SeCreateSymbolicLinkPrivilege" -VerboseOutput:$VerboseOutput
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform user rights assignment remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
