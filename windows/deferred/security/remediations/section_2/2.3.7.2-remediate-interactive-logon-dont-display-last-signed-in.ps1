# Remediation: 2.3.7.2
# CIS Benchmark: 2.3.7.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
$result = Set-RegistryValue @config
        $RemediationResults += $result
        
        if ($result.Success) {
            Write-Host "  SUCCESS: $($config.Description)" -ForegroundColor Green
        } else {
            Write-Host "  FAILED: $($config.Description)" -ForegroundColor Red
            Write-Host "    Error: $($result.ErrorMessage)" -ForegroundColor Red
            $OverallSuccess = $false
        }
}
