# Audit: Bluetooth Support Service (bthserv) setting on Windows
# CIS Benchmark: 5.2 (L2) Ensure 'Bluetooth Support Service (bthserv)' is set to 'Disabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module and invoke audit with boilerplate handling
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
    # Use Invoke-CISAudit with Service audit type
    Invoke-CISAudit -CIS_ID "5.2" -AuditType "Service" -ServiceName "bthserv" -Section "5"
}
