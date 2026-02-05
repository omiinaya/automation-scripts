# Audit: 5.39
# CIS Benchmark: 5.39 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Service Audit: Xbox Live Auth Manager (XblAuthManager)"
    }
    
    # Use Invoke-CISAudit with Service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "5.39" -AuditType "Service" -ServiceName "XblAuthManager" -VerboseOutput:$VerboseOutput -Section "5"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform service audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
