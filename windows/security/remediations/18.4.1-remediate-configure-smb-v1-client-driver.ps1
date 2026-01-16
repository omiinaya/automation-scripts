# Remediation: Configure SMB v1 client driver setting on Windows
# CIS Benchmark: 18.4.1 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)'
# Refactored to use CISRemediation framework

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Client Driver Remediation: Configure SMB v1 Client Driver"
    }
    
    # Invoke remediation using CISRemediation framework with custom script block
    $result = Invoke-CISRemediation -CIS_ID "18.4.1" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
        try {
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
    }
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 client driver remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}