# Remediation: 5.40
# CIS Benchmark: 5.40 (L1)

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot "..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

Invoke-CISRemediationScript -ScriptRoot $scriptRoot -RemediationBlock {
if ($VerboseOutput) {
        Write-SectionHeader -Title "Service Remediation: Xbox Live Game Save (XblGameSave)"
    }
    
    # Use Invoke-CISRemediation with Custom remediation type for service configuration
    $remediationResult = Invoke-CISRemediation -CIS_ID "5.40" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "5" -CustomScriptBlock {
            # Check if service exists
            if (Test-ServiceExists -ServiceName "XblGameSave") {
                # Get current service status
                $service = Get-Service -Name "XblGameSave"
                $previousStatus = $service.Status.ToString()
                
                # Set service startup type to Disabled
                Set-Service -Name "XblGameSave" -StartupType Disabled
                
                # Stop the service if it's running
                if ($service.Status -eq "Running") {
                    Stop-Service -Name "XblGameSave" -Force
                }
                
                # Verify the change
                $updatedService = Get-Service -Name "XblGameSave"
                
                return @{
                    PreviousValue = "Startup: $($service.StartType), Status: $previousStatus"
                    NewValue = "Startup: Disabled, Status: $($updatedService.Status)"
                }
            } else {
                # Service doesn't exist, which is compliant
                return @{
                    PreviousValue = "Service not found"
                    NewValue = "Service not found (compliant)"
                }
            }
        } catch {
            throw "Failed to remediate XblGameSave: $($_.Exception.Message)"
}
