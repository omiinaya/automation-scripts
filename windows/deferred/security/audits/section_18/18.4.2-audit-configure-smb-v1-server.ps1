# Audit: 18.4.2
# CIS Benchmark: 18.4.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Server Audit: Configure SMB v1 Server"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.2" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -RegistryValueName "SMB1" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 server audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
