# Audit: Allow Online Tips setting on Windows
# CIS Benchmark: 18.1.3 (L2) Ensure 'Allow Online Tips' is set to 'Disabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Use Invoke-CISAudit with registry audit type
    Invoke-CISAudit -CIS_ID "18.1.3" -AuditType "Registry" -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -RegistryValueName "AllowOnlineTips" -Section "18"
}
