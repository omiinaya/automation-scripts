# Remediation: 18.4.1
# CIS Benchmark: 18.4.1 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Client Driver Remediation: Configure SMB v1 Client Driver"
    }
    
    # Invoke remediation using CISRemediation framework with custom script block
    $result = Invoke-CISRemediation -CIS_ID "18.4.1" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
            # Check if the service exists
            $service = Get-Service -Name "mrxsmb10" -ErrorAction SilentlyContinue
            
            if ($service) {
                # Stop the service if running
                if ($service.Status -eq "Running") {
                    Stop-Service -Name "mrxsmb10" -Force
                }
                
                # Disable the service
                Set-Service -Name "mrxsmb10" -StartupType Disabled
                
                # Also set the registry value to disable the driver
                $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10"
                if (-not (Test-Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                }
                Set-ItemProperty -Path $registryPath -Name "Start" -Value 4 -Type DWord
                
                return @{
                    PreviousValue = "Enabled"
                    NewValue = "Disabled"
                }
            } else {
                # Service doesn't exist, create registry entry to disable it
                $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10"
                if (-not (Test-Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                }
                Set-ItemProperty -Path $registryPath -Name "Start" -Value 4 -Type DWord
                
                return @{
                    PreviousValue = "Not Configured"
                    NewValue = "Disabled"
                }
            }
        } catch {
            throw "Failed to disable SMB v1 client driver: $($_.Exception.Message)"
}
