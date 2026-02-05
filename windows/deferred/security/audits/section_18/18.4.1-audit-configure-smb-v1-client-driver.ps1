# Audit: 18.4.1
# CIS Benchmark: 18.4.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Client Driver Audit: Configure SMB v1 Client Driver"
    }
    
    # Use Invoke-CISAudit with service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.1" -AuditType "Service" -ServiceName "mrxsmb10" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 client driver audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
