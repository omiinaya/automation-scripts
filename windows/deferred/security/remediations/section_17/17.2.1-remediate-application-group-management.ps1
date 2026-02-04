# Remediation: Audit Application Group Management setting on Windows
# CIS Benchmark: 17.2.1 (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Configure audit policy using auditpol.exe
$remediationBlock = {
    # Use Custom remediation type for auditpol.exe configuration
    Invoke-CISRemediation -CIS_ID "17.2.1" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "17" -CustomScriptBlock {
        # Get current setting first
        $auditResult = auditpol /get /subcategory:"{0cce9239-69ae-11d9-bed3-505054503030}"
        $previousSetting = "Unknown"
        foreach ($line in $auditResult) {
            if ($line -match "Application Group Management" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
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
        $setResult = auditpol /set /subcategory:"{0cce9239-69ae-11d9-bed3-505054503030}" /success:enable /failure:enable
        
        if ($LASTEXITCODE -eq 0) {
            # Verify the change
            Start-Sleep -Seconds 2
            $verifyResult = auditpol /get /subcategory:"{0cce9239-69ae-11d9-bed3-505054503030}"
            $newSetting = "Unknown"
            foreach ($line in $verifyResult) {
                if ($line -match "Application Group Management" -and $line -match "Success and Failure|Success|Failure|No Auditing") {
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
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
