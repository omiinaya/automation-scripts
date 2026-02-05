# Audit: 18.4.4
# CIS Benchmark: 18.4.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SEHOP Audit: Enable Structured Exception Handling Overwrite Protection"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.4" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -RegistryValueName "DisableExceptionChainValidation" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SEHOP audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
