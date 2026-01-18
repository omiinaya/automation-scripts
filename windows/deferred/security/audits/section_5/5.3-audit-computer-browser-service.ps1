# Audit: Computer Browser Service (Browser) setting on Windows
# CIS Benchmark: 5.3 (L1) Ensure 'Computer Browser (Browser)' is set to 'Disabled' or 'Not Installed'
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
        Write-SectionHeader -Title "Service Audit: Computer Browser Service (Browser)"
    }
    
    # Use Invoke-CISAudit with Service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "5.3" -AuditType "Service" -ServiceName "Browser" -VerboseOutput:$VerboseOutput -Section "5"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform service audit: $($_.Exception.Message)"
    } else {
        $false
    }
}