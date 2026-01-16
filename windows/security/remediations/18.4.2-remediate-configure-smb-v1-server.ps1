# Remediation: Configure SMB v1 server setting on Windows
# CIS Benchmark: 18.4.2 (L1) Ensure 'Configure SMB v1 server' is set to 'Disabled'
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
        Write-SectionHeader -Title "SMB v1 Server Remediation: Configure SMB v1 Server"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.2" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -RegistryValueName "SMB1" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 server remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}