# Remediation: 18.4.3
# CIS Benchmark: 18.4.3 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Certificate Padding Remediation: Enable Certificate Padding"
    }
    
    # Invoke remediation using CISRemediation framework with custom script block
    $result = Invoke-CISRemediation -CIS_ID "18.4.3" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
            # Set certificate padding in both registry locations
            $registryPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config",
                "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"
            )
            
            foreach ($registryPath in $registryPaths) {
                if (-not (Test-Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                }
                Set-ItemProperty -Path $registryPath -Name "EnableCertPaddingCheck" -Value 1 -Type DWord
            }
            
            return @{
                PreviousValue = "Not Set"
                NewValue = "Enabled"
            }
        } catch {
            throw "Failed to enable certificate padding: $($_.Exception.Message)"
}
