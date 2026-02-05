# Audit: 18.4.6
# CIS Benchmark: 18.4.6 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "WDigest Authentication Audit: WDigest Authentication"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.6" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -RegistryValueName "UseLogonCredential" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform WDigest authentication audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
