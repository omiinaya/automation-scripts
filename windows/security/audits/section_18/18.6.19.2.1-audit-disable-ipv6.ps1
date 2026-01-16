# Audit: Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
# CIS Benchmark: 18.6.19.2.1 (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')
# Refactored to use CIS Framework Module

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
        Write-SectionHeader -Title "IPv6 Configuration Audit: Disable IPv6 Components"
    }
    
    # Use Invoke-CISAudit with Registry audit type for IPv6 DisabledComponents
    $auditResult = Invoke-CISAudit -CIS_ID "18.6.19.2.1" -AuditType "Registry" -VerboseOutput:$VerboseOutput -Section "18" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" -RegistryValueName "DisabledComponents"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform IPv6 configuration audit: $($_.Exception.Message)"
    } else {
        $false
    }
}