# Audit: Configure SMB v1 client driver setting on Windows
# CIS Benchmark: 18.4.1 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)'
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
        Write-SectionHeader -Title "SMB v1 Client Driver Audit: Configure SMB v1 Client Driver"
    }
    
    # Use Invoke-CISAudit with service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "18.4.1" -AuditType "Service" -ServiceName "mrxsmb10" -VerboseOutput:$VerboseOutput -Section "18"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform SMB v1 client driver audit: $($_.Exception.Message)"
    } else {
        $false
    }
}