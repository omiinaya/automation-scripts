# Remediation: Print Spooler (Spooler) setting on Windows
# CIS Benchmark: 5.13 (L2) Ensure 'Print Spooler (Spooler)' is set to 'Disabled'

[CmdletBinding()]
param()

# Import ScriptTemplates module
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ScriptTemplates.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Remediation-specific logic: Disable Print Spooler service
$remediationBlock = {
    # Use Custom remediation type for service configuration
    Invoke-CISRemediation -CIS_ID "5.13" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "5" -CustomScriptBlock {
        # Check if service exists
        if (Test-ServiceExists -ServiceName "Spooler") {
            # Get current service status
            $service = Get-Service -Name "Spooler"
            $previousStatus = $service.Status.ToString()
            
            # Set service startup type to Disabled
            Set-Service -Name "Spooler" -StartupType Disabled
            
            # Stop the service if it's running
            if ($service.Status -eq "Running") {
                Stop-Service -Name "Spooler" -Force
            }
            
            # Verify the change
            $updatedService = Get-Service -Name "Spooler"
            
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
    }
}

# Execute remediation using template function
Invoke-CISRemediationScript -ScriptRoot $PSScriptRoot -RemediationBlock $remediationBlock
