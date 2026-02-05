# Audit: 17.5.3
# CIS Benchmark: 17.5.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
# Get current audit policy setting for Logoff subcategory
        $auditResult = auditpol /get /subcategory:"{0cce9216-69ae-11d9-bed3-505054503030}"
        $currentSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "Logoff" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                if ($line -match "Success and Failure") {
                    $currentSetting = "Success and Failure"
                } elseif ($line -match "Success") {
                    $currentSetting = "Success"
                } elseif ($line -match "Failure") {
                    $currentSetting = "Failure"
                } elseif ($line -match "No Auditing") {
                    $currentSetting = "No Auditing"
                }
                break
            }
        }
        
        # Check compliance: must include Success auditing
        $isCompliant = ($currentSetting -eq "Success" -or $currentSetting -eq "Success and Failure")
        
        return @{
            CurrentValue = $currentSetting
            Source = "auditpol.exe"
            Details = "Subcategory GUID: {0cce9216-69ae-11d9-bed3-505054503030}"
            IsCompliant = $isCompliant
        }
}
