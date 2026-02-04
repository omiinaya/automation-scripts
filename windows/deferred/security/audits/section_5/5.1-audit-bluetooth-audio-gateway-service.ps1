# Audit: Bluetooth Audio Gateway Service (BTAGService) setting on Windows
# CIS Benchmark: 5.1 (L2) Ensure 'Bluetooth Audio Gateway Service (BTAGService)' is set to 'Disabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Use Invoke-CISAudit with Service audit type
    Invoke-CISAudit -CIS_ID "5.1" -AuditType "Service" -ServiceName "BTAGService" -Section "5"
}
