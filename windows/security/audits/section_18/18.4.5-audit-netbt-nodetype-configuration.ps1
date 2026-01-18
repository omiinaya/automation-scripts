# Audit: NetBT NodeType configuration setting on Windows
# CIS Benchmark: 18.4.5 (L1) Ensure 'NetBT NodeType configuration' is set to 'Enabled: P-node (recommended)'
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
        Write-SectionHeader -Title "NetBT NodeType Audit: NetBT NodeType Configuration"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.5" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -RegistryValueName "NodeType" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform NetBT NodeType audit: $($_.Exception.Message)"
    } else {
        $false
    }
}