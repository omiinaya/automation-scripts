# Audit: 17.5.5
# CIS Benchmark: 17.5.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
# Run auditpol.exe to get the current configuration
        $auditResult = auditpol /get /subcategory:"{0cce921c-69ae-11d9-bed3-505054503030}"
        
        # Parse the output to extract the current setting
        $currentSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "Other Logon/Logoff Events" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
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
        
        # Determine compliance (must be Success and Failure)
        $isCompliant = ($currentSetting -eq "Success and Failure")
        
        return @{
            CurrentValue = $currentSetting
            Source = "auditpol.exe"
            Details = "Subcategory GUID: {0cce921c-69ae-11d9-bed3-505054503030}"
            IsCompliant = $isCompliant
        }
}
