# Audit: 18.1.1.1
# CIS Benchmark: 18.1.1.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Lock Screen Camera Audit: Prevent Enabling Lock Screen Camera"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.1.1.1" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenCamera" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the structured audit result
    return $auditResult
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform lock screen camera audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
