# Audit: 18.4.5
# CIS Benchmark: 18.4.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "NetBT NodeType Audit: NetBT NodeType Configuration"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.5" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -RegistryValueName "NodeType" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform NetBT NodeType audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
