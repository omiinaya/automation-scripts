# Remediation: 18.1.1.1
# CIS Benchmark: 18.1.1.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Lock Screen Camera Remediation: Prevent Enabling Lock Screen Camera"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.1.1.1" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenCamera" -RegistryValueData 1 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform lock screen camera remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
