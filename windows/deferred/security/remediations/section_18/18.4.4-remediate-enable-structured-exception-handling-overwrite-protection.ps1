# Remediation: 18.4.4
# CIS Benchmark: 18.4.4 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SEHOP Remediation: Enable Structured Exception Handling Overwrite Protection"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.4" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -RegistryValueName "DisableExceptionChainValidation" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SEHOP remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
