# Audit: Problem Reports and Solutions Control Panel Support (wercplsupport) setting on Windows
# CIS Benchmark: 5.14 (L2) Ensure 'Problem Reports and Solutions Control Panel Support (wercplsupport)' is set to 'Disabled'
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
        Write-SectionHeader -Title "Service Audit: Problem Reports and Solutions Control Panel Support (wercplsupport)"
    }
    
    # Use Invoke-CISAudit with Service audit type
    $auditResult = Invoke-CISAudit -CIS_ID "5.14" -AuditType "Service" -ServiceName "wercplsupport" -VerboseOutput:$VerboseOutput -Section "5"
    
    # Return the compliance status
    $auditResult.IsCompliant
} catch {
    if ($VerboseOutput) {
        Wait-OnError -ErrorMessage "Failed to perform service audit: $($_.Exception.Message)"
    } else {
        $false
    }
}