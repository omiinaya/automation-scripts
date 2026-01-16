# Audit: Configure SMB v1 server setting on Windows
# CIS Benchmark: 18.4.2 (L1) Ensure 'Configure SMB v1 server' is set to 'Disabled'
# Refactored to use CIS Framework Module

[CmdletBinding()]
param()

$VerboseOutput = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')

# Import the required modules using ModuleIndex
$modulePath = Join-Path $PSScriptRoot "..\..\modules\ModuleIndex.psm1"
Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Check admin rights and handle elevation
if (-not (Test-AdminRights)) {
    Invoke-Elevation
}

try {
    if ($VerboseOutput) {
        Write-SectionHeader -Title "SMB v1 Server Audit: Configure SMB v1 Server"
    }
    
    # Use Invoke-CISAudit with registry audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.2" -AuditType "Registry" -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -RegistryValueName "SMB1" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 server audit: $($_.Exception.Message)"
    } else {
        $false
    }
}