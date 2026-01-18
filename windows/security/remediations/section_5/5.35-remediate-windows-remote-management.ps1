# Remediation: Windows Remote Management (WinRM) setting on Windows
# CIS Benchmark: 5.35 (L2) Ensure 'Windows Remote Management (WS-Management) (WinRM)' is set to 'Disabled'
# Refactored to use CIS Remediation Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Service Remediation: Windows Remote Management (WinRM)"
    }
    
    # Use Invoke-CISRemediation with Custom remediation type for service configuration
    $remediationResult = Invoke-CISRemediation -CIS_ID "5.35" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "5" -CustomScriptBlock {
        try {
            # Check if service exists
            if (Test-ServiceExists -ServiceName "WinRM") {
                # Get current service status
                $service = Get-Service -Name "WinRM"
                $previousStatus = $service.Status.ToString()
                
                # Set service startup type to Disabled
                Set-Service -Name "WinRM" -StartupType Disabled
                
                # Stop the service if it's running
                if ($service.Status -eq "Running") {
                    Stop-Service -Name "WinRM" -Force
                }
                
                # Verify the change
                $updatedService = Get-Service -Name "WinRM"
                
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
            throw "Failed to remediate WinRM: $($_.Exception.Message)"
        }
    }
    
    # Return the remediation status
    $remediationResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform service remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}