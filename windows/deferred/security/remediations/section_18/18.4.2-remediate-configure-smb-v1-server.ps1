# Remediation: 18.4.2
# CIS Benchmark: 18.4.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Server Remediation: Configure SMB v1 Server"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.2" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -RegistryValueName "SMB1" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 server remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
