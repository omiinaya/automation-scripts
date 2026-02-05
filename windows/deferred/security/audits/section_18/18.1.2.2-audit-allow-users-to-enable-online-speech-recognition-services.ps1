# Audit: 18.1.2.2
# CIS Benchmark: 18.1.2.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Speech Recognition Audit: Allow Users to Enable Online Speech Recognition Services"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.1.2.2" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -RegistryValueName "AllowInputPersonalization" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform speech recognition audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
