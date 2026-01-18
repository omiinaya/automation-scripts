# Remediation: Enable Certificate Padding setting on Windows
# CIS Benchmark: 18.4.3 (L1) Ensure 'Enable Certificate Padding' is set to 'Enabled'
# Refactored to use CISRemediation framework

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Certificate Padding Remediation: Enable Certificate Padding"
    }
    
    # Invoke remediation using CISRemediation framework with custom script block
    $result = Invoke-CISRemediation -CIS_ID "18.4.3" -RemediationType "Custom" -VerboseOutput:$VerboseOutput -Section "18" -CustomScriptBlock {
        try {
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
    }
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform certificate padding remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}