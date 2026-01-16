# Remediation: Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
# CIS Benchmark: 18.6.19.2.1 (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
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
        Write-SectionHeader -Title "IPv6 Configuration Remediation: Disable IPv6 Components"
    }
    
    # Invoke remediation using CISRemediation framework for registry-based remediation
    $result = Invoke-CISRemediation -CIS_ID "18.6.19.2.1" -RemediationType "Registry" -VerboseOutput:$VerboseOutput -Section "18" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" -RegistryValueName "DisabledComponents" -RegistryValueData 255 -RegistryValueType "DWord"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform IPv6 configuration remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}