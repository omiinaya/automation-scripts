# Remediation: NetBT NodeType configuration setting on Windows
# CIS Benchmark: 18.4.5 (L1) Ensure 'NetBT NodeType configuration' is set to 'Enabled: P-node (recommended)'
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
        Write-SectionHeader -Title "NetBT NodeType Remediation: NetBT NodeType Configuration"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.5" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -RegistryValueName "NodeType" -RegistryValueData 2 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform NetBT NodeType remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}