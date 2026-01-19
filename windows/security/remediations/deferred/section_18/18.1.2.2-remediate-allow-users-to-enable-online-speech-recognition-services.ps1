# Remediation: Allow users to enable online speech recognition services setting on Windows
# CIS Benchmark: 18.1.2.2 (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled'
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
        Write-SectionHeader -Title "Speech Recognition Remediation: Allow Users to Enable Online Speech Recognition Services"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.1.2.2" -RemediationType "Registry" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -RegistryValueName "AllowInputPersonalization" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform speech recognition remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}