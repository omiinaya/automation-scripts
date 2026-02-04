# Audit: MSS: (NoNameReleaseOnDemand) setting on Windows
# CIS Benchmark: 18.5.7 (L1) Ensure 'MSS: (NoNameReleaseOnDemand)' is set to '1'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Use Invoke-CISAudit with registry audit type
    Invoke-CISAudit -CIS_ID "18.5.7" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -RegistryValueName "NoNameReleaseOnDemand" -Section "18"
}
