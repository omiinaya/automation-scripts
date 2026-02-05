# Remediation: 18.1.1.2
# CIS Benchmark: 18.1.1.2 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Lock Screen Slide Show Remediation: Prevent Enabling Lock Screen Slide Show"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.1.1.2" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -RegistryValueName "NoLockScreenSlideshow" -RegistryValueData 1 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform lock screen slide show remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}
