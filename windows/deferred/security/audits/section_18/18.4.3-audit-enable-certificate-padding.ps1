# Audit: 18.4.3
# CIS Benchmark: 18.4.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISAuditScript -ScriptRoot $scriptRoot -AuditBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Certificate Padding Audit: Enable Certificate Padding"
    }
    
    # Use Invoke-CISAudit with custom script block for certificate padding audit
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.3" -AuditType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
        # Check both registry locations for certificate padding
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
        )
        
        $currentValue = "Not Set"
        $source = "Registry"
        $details = ""
        
        foreach ($registryPath in $registryPaths) {
            if (Test-Path $registryPath) {
                $value = Get-ItemProperty -Path $registryPath -Name "EnableCertPaddingCheck" -ErrorAction SilentlyContinue
                if ($value) {
                    $currentValue = $value.EnableCertPaddingCheck
                    $details = "Registry path: $registryPath"
                    break
                }
            }
        }
        
        return @{
            CurrentValue = $currentValue
            Source = $source
            Details = $details
        }
    }
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform certificate padding audit: $($_.Exception.Message)"
    } else {
        $false
    }
}
