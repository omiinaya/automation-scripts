# Remediation: Turn off Microsoft Peer-to-Peer Networking Services
# CIS Benchmark: 18.6.10.2 (L2) Ensure 'Turn off Microsoft Peer-to-Peer Networking Services' is set to 'Enabled'
# Refactored to use CISRemediation framework

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the Windows modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "Peer-to-Peer Networking Services Remediation: Turn off Microsoft Peer-to-Peer Networking Services"
    }
    
    # Invoke remediation using CISRemediation framework for registry-based remediation
    $result = Invoke-CISRemediation -CIS_ID "18.6.10.2" -RemediationType "Registry" -VerboseOutput:$VerboseOutput -Section "18" -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Peernet" -RegistryValueName "Disabled" -RegistryValueData 1 -RegistryValueType "DWord"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform Peer-to-Peer Networking Services remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}