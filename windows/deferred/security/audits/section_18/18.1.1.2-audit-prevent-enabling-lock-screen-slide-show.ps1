# Audit: 18.1.1.2
# CIS Benchmark: 18.1.1.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Lock Screen Slide Show Audit: Prevent Enabling Lock Screen Slide Show"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.1.1.2" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenSlideshow" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform lock screen slide show audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
