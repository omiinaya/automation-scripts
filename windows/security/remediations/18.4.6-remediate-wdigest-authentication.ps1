# Remediation: WDigest Authentication setting on Windows
# CIS Benchmark: 18.4.6 (L1) Ensure 'WDigest Authentication' is set to 'Disabled'
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
        Write-SectionHeader -Title "WDigest Authentication Remediation: WDigest Authentication"
    }
    
    # Invoke remediation using CISRemediation framework
    $result = Invoke-CISRemediation -CIS_ID "18.4.6" -RemediationType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -RegistryValueName "UseLogonCredential" -RegistryValueData 0 -RegistryValueType "DWord" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return appropriate result based on verbose mode
    if ($VerboseOutput) {
        $result
    } else {
        $result.IsCompliant
    }
    
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform WDigest authentication remediation: $($_.Exception.Message)"
    } else {
        $false
    }
}