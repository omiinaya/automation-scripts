# Remediation: 17.1.1
# CIS Benchmark: 17.1.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
# Get current setting first
        $auditResult = auditpol /get /subcategory:"{0cce923f-69ae-11d9-bed3-505054503030}"
        $previousSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "Credential Validation" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                if ($line -match "Success and Failure") {
                    $previousSetting = "Success and Failure"
                } elseif ($line -match "Success") {
                    $previousSetting = "Success"
                } elseif ($line -match "Failure") {
                    $previousSetting = "Failure"
                } elseif ($line -match "No Auditing") {
                    $previousSetting = "No Auditing"
                }
                break
            }
        }
        
        # Set the audit policy to Success and Failure
        $setResult = auditpol /set /subcategory:"{0cce923f-69ae-11d9-bed3-505054503030}" /success:enable /failure:enable
        
        if ($LASTEXITCODE -eq 0) {
            # Verify the change
            Start-Sleep -Seconds 2
            $verifyResult = auditpol /get /subcategory:"{0cce923f-69ae-11d9-bed3-505054503030}"
            $newSetting = "Unknown"
            foreach ($line in $verifyResult) {
                if ($line -match "Credential Validation" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
                    if ($line -match "Success and Failure") {
                        $newSetting = "Success and Failure"
                    }
                    break
                }
            }
            
            return @{
                PreviousValue = $previousSetting
                NewValue = $newSetting
                IsCompliant = ($newSetting -eq "Success and Failure")
            }
        } else {
            return @{
                PreviousValue = $previousSetting
                NewValue = "Failed to set"
                IsCompliant = $false
            }
        }
}
