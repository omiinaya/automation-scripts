# Audit: 1.1.6
# CIS Benchmark: 1.1.6 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Password Policy Audit: Relax Minimum Password Length Limits"
    }
    
    # Use Invoke-CISAudit with registry audit for relax password length limits
    $auditResult = Invoke-CISAudit -CIS_ID "1.1.6" -AuditType "Registry" -VerboseOutput:$VerboseOutput -Section "1" -RegistryPath "HKLM:\System\CurrentControlSet\Control\SAM" -RegistryValueName "RelaxMinimumPasswordLengthLimits"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform password policy audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
