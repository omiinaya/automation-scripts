# Audit: 5.28
# CIS Benchmark: 5.28 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Service Audit: Web Management Service (WMSvc)"
    }
    
    # Use Invoke-CISAudit with Service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "5.28" -AuditType "Service" -ServiceName "WMSvc" -VerboseOutput:$VerboseOutput -Section "5"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform service audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
