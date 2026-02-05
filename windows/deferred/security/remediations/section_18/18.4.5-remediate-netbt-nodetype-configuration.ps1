# Remediation: 18.4.5
# CIS Benchmark: 18.4.5 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "NetBT NodeType Remediation: NetBT NodeType Configuration"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.5" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -RegistryValueName "NodeType" -RegistryValueData 2 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform NetBT NodeType remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
